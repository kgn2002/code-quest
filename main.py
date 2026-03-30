from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from supabase import create_client, Client
import sys, ast, io, hashlib, json, numpy as np
from datetime import datetime

# ── CONFIG ────────────────────────────────────────────────────────────────────
url = "https://czqudediffgptxndhwzt.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6cXVkZWRpZmZncHR4bmRod3p0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzA4MjczNSwiZXhwIjoyMDgyNjU4NzM1fQ.Eb2moOepnkj803QvhA3ZNW45Qarwpj5K9L1BHOMwYW0"
supabase: Client = create_client(url, key)
app      = FastAPI()
ALPHA    = 0.1
GAMMA    = 0.9

# ── BLOCKCHAIN ────────────────────────────────────────────────────────────────
_GENESIS = "0" * 64

def _sha256(data: str) -> str:
    return hashlib.sha256(data.encode()).hexdigest()

def _make_block(index: int, data: dict, prev_hash: str) -> dict:
    ts = datetime.utcnow().isoformat()
    content = json.dumps({"index": index, "timestamp": ts,
                           "data": data, "prev_hash": prev_hash}, sort_keys=True)
    return {"index": index, "timestamp": ts, "data": data,
            "prev_hash": prev_hash, "hash": _sha256(content)}

def _last_block() -> dict:
    try:
        r = supabase.table("certificates").select("index,hash") \
                    .order("index", desc=True).limit(1).execute()
        if r.data: return r.data[0]
    except Exception: pass
    return {"index": 0, "hash": _GENESIS}

# ── LOOP GUARD ────────────────────────────────────────────────────────────────
_GUARD = """
_lc=0
def _chk():
    global _lc; _lc+=1
    if _lc>500: raise RuntimeError("Infinite loop detected")
"""
def _inject(src: str) -> str:
    try: tree = ast.parse(src)
    except SyntaxError: return src
    class G(ast.NodeTransformer):
        def _c(self): return ast.Expr(ast.Call(
            func=ast.Name(id='_chk',ctx=ast.Load()),args=[],keywords=[]))
        def visit_While(self, n): self.generic_visit(n); n.body.insert(0,self._c()); return n
        def visit_For  (self, n): self.generic_visit(n); n.body.insert(0,self._c()); return n
    t = G().visit(tree); ast.fix_missing_locations(t)
    try: return ast.unparse(t)
    except: return src

def _safe_q(raw) -> np.ndarray:
    try:
        a = np.array(raw, dtype=float)
        if a.shape == (3,3): return a
    except: pass
    return np.zeros((3,3))

# ── MODELS ────────────────────────────────────────────────────────────────────
class CodeRequest(BaseModel):
    code: str
    expected_output: str

class LearningMetrics(BaseModel):
    profile_id: str
    location_id: str
    errors: int
    latency: float

class CertificateRequest(BaseModel):
    profile_id: str
    username: str
    total_xp: int
    completed_quests: list[str]

# ── ENDPOINTS ─────────────────────────────────────────────────────────────────

@app.get("/")
def health():
    return {"project": "Code-Quest AI Engine", "status": "running",
            "sprints": "4 (Fuzzy) + 5 (Q-Learning) + Blockchain Certificate"}

@app.post("/evaluate")
async def evaluate(req: CodeRequest):
    try:
        guarded = _GUARD + "\n" + _inject(req.code)
        buf = io.StringIO(); ns = {}
        old, sys.stdout = sys.stdout, buf
        try: exec(compile(guarded, "<student>", "exec"), ns)
        finally: sys.stdout = old
        out = buf.getvalue().rstrip("\n")
        ok  = out == req.expected_output.strip()
        return {"is_correct": ok, "output": out, "error": None}
    except RuntimeError:
        return {"is_correct": False, "output": "",
                "error": "⚠️ Infinite loop!\n\nYour loop ran over 500 steps.\nDid you forget i += 1?"}
    except Exception as e:
        return {"is_correct": False, "output": "", "error": str(e)}

@app.post("/update-learning")
async def update_learning(m: LearningMetrics):
    try:
        acc   = max(0.0, 1.0 - m.errors / 5)
        speed = max(0.0, 1.0 - m.latency / 60)
        score = acc * 0.7 + speed * 0.3
        level = "advanced" if score > 0.8 else ("intermediate" if score > 0.4 else "basic")
        reward= round(score * 10, 2)
        state = 2 if level == "advanced" else (1 if level == "intermediate" else 0)

        try:
            r   = supabase.table("profiles").select("q_table").eq("id", m.profile_id).single().execute()
            raw = r.data.get("q_table") if r.data else None
        except: raw = None
        q = _safe_q(raw)
        q[state][state] += ALPHA * (reward + GAMMA * float(np.max(q[state])) - q[state][state])

        try: supabase.table("profiles").update({"q_table": q.tolist()}).eq("id", m.profile_id).execute()
        except Exception as e: print(f"⚠️ q_table: {e}")

        try:
            supabase.table("map_analytics").insert({
                "profile_id": m.profile_id, "location_id": m.location_id,
                "errors": m.errors, "latency": m.latency,
                "mastery_score": round(score, 2)}).execute()
        except Exception as e: print(f"⚠️ analytics: {e}")

        print(f"\n{'─'*35}")
        print(f"📍 {m.location_id}  |  Score: {round(score,2)}  |  {level.upper()}")
        print(f"🎁 Reward: {reward}  |  Q[{state}]: {round(q[state][state],4)}")
        print(f"{'─'*35}")

        return {"status": "ok", "recommendation": level,
                "fuzzy_score": round(score, 2), "reward": reward}
    except Exception as e:
        print(f"💥 update-learning: {e}")
        raise HTTPException(500, str(e))

# All quests that must be genuinely completed before MasterChallenge is valid.
# Backend verifies this against Supabase — not just what the client sends.
_REQUIRED_FOR_MASTER = {
    "PythonHouse", "PythonTable", "PythonLibrary", "PythonGarden", "PythonCave",
    "TreasureBox_final",
    "GoblinHouse", "SnowToy", "Computer", "Coins", "PondBuilding",
    "MasterChallenge",
}

_REQUIRED_BEFORE_MASTER = _REQUIRED_FOR_MASTER - {"MasterChallenge"}

@app.get("/verify-unlock/{profile_id}")
async def verify_unlock(profile_id: str):
    """
    Called by Flutter before showing the MasterChallenge overlay.
    Fetches completed_quests directly from Supabase (authoritative source)
    and confirms all prerequisites are met.
    Returns: { "unlocked": bool, "missing": [...], "server_completed": [...] }
    """
    try:
        resp = supabase.table("profiles") \
            .select("completed_quests") \
            .eq("id", profile_id) \
            .single() \
            .execute()
        server_completed = set(resp.data.get("completed_quests") or [])
        missing = _REQUIRED_BEFORE_MASTER - server_completed
        unlocked = len(missing) == 0
        print(f"🔐 verify-unlock [{profile_id[:8]}...]: unlocked={unlocked}, missing={sorted(missing)}")
        return {
            "unlocked":         unlocked,
            "missing":          sorted(missing),
            "server_completed": sorted(server_completed),
        }
    except Exception as e:
        print(f"💥 verify-unlock: {e}")
        raise HTTPException(500, str(e))


@app.post("/generate-certificate")
async def generate_certificate(req: CertificateRequest):
    try:
        # ── SERVER-SIDE PREREQUISITE CHECK (Path 3 defence) ──────────────
        # Fetch the authoritative completed_quests from Supabase directly.
        # We do NOT trust req.completed_quests — the client could send anything.
        try:
            profile_resp = supabase.table("profiles") \
                .select("completed_quests") \
                .eq("id", req.profile_id) \
                .single() \
                .execute()
            server_completed = set(profile_resp.data.get("completed_quests") or [])
        except Exception as e:
            print(f"⚠️ Could not verify prereqs from Supabase: {e}")
            raise HTTPException(403, "Could not verify quest completion. Try again.")

        missing = _REQUIRED_FOR_MASTER - server_completed
        if missing:
            missing_list = ", ".join(sorted(missing))
            print(f"🚫 Certificate denied for {req.profile_id} — missing: {missing_list}")
            raise HTTPException(
                403,
                f"Certificate not earned yet. Missing quests: {missing_list}"
            )

        # ── All prereqs confirmed — mint the certificate ──────────────────
        cert_data = {
            "profile_id":      req.profile_id,
            "username":        req.username,
            "total_xp":        req.total_xp,
            "quests_completed": len(server_completed),
            "completed_quests": sorted(server_completed),  # use server truth
            "issued_at":       datetime.utcnow().isoformat(),
            "course":          "Python Programming — CodeQuest",
            "issuer":          "CodeQuest Academy",
        }
        last  = _last_block()
        block = _make_block(last["index"] + 1, cert_data, last["hash"])

        try:
            supabase.table("certificates").insert({
                "index":      block["index"],
                "timestamp":  block["timestamp"],
                "profile_id": req.profile_id,
                "username":   req.username,
                "data":       block["data"],
                "prev_hash":  block["prev_hash"],
                "hash":       block["hash"],
            }).execute()
            print(f"🏆 Block #{block['index']} minted — {block['hash'][:20]}...")
        except Exception as e:
            print(f"⚠️ DB insert: {e}")

        return {"success": True, "block": block,
                "certificate_hash": block["hash"],
                "block_index": block["index"]}
    except HTTPException:
        raise
    except Exception as e:
        print(f"💥 certificate: {e}")
        raise HTTPException(500, str(e))

@app.get("/certificate/{cert_hash}", response_class=HTMLResponse)
async def view_certificate(cert_hash: str):
    try:
        r = supabase.table("certificates").select("*").eq("hash", cert_hash).single().execute()
        if not r.data: raise HTTPException(404, "Certificate not found")
        cert = r.data; data = cert["data"]
    except HTTPException: raise
    except Exception as e: raise HTTPException(500, str(e))

    name   = data.get("username", "Hero")
    issued = data.get("issued_at", "")[:10]
    xp     = data.get("total_xp", 0)
    count  = data.get("quests_completed", 0)
    idx    = cert.get("index", 1)
    prev   = cert.get("prev_hash", "")
    h      = cert_hash

    topics = [
        ("🖨️","Print & Syntax"),("📦","Variables"),("➕","Math & Operators"),
        ("🔀","If / Else"),("📋","Lists"),("🔁","For Loops"),
        ("⚙️","Functions"),("🔤","Strings"),("📚","Dictionaries"),
        ("✅","Booleans"),("🔢","Type Conversion"),("🔄","While Loops"),("🧬","Regex & Slicing"),
    ]
    chips = "".join(f'<div class="chip"><span>{e}</span>{t}</div>' for e,t in topics)

    html = f"""<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>CodeQuest Certificate — {name}</title>
<link href="https://fonts.googleapis.com/css2?family=Cinzel+Decorative:wght@700;900&family=Crimson+Pro:ital,wght@0,300;1,300&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
<style>
*{{box-sizing:border-box;margin:0;padding:0}}
:root{{--gold:#f0c040;--gold2:#c8960c;--dark:#07071a;--panel:#10101e;--border:#2a2a48;
      --green:#00ffaa;--cyan:#00d4ff;--purple:#9b6dff;--text:#e8e0ff;--dim:#8888aa}}
@keyframes shimmer{{0%{{background-position:-200% center}}100%{{background-position:200% center}}}}
@keyframes float{{0%,100%{{transform:translateY(0)}}50%{{transform:translateY(-8px)}}}}
@keyframes fadeUp{{from{{opacity:0;transform:translateY(24px)}}to{{opacity:1;transform:translateY(0)}}}}
@keyframes twinkle{{50%{{opacity:.1}}}}
body{{background:var(--dark);color:var(--text);font-family:'Crimson Pro',Georgia,serif;min-height:100vh;overflow-x:hidden}}
body::after{{content:'';position:fixed;inset:0;background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,0,0,.07) 2px,rgba(0,0,0,.07) 4px);pointer-events:none;z-index:99}}
#stars{{position:fixed;inset:0;pointer-events:none}}
.star{{position:absolute;width:2px;height:2px;background:#fff;border-radius:50%;animation:twinkle var(--d,3s) ease-in-out infinite;animation-delay:var(--delay,0s)}}
.page{{max-width:820px;margin:0 auto;padding:36px 18px 70px;animation:fadeUp .8s ease both}}
.lbl{{text-align:center;font-family:'JetBrains Mono',monospace;font-size:10px;letter-spacing:4px;color:var(--dim);text-transform:uppercase}}
.title{{font-family:'Cinzel Decorative',serif;font-size:clamp(26px,6vw,50px);font-weight:900;text-align:center;
        background:linear-gradient(135deg,var(--gold2),#fff8dc 40%,var(--gold) 60%,var(--gold2));
        background-size:200% auto;-webkit-background-clip:text;-webkit-text-fill-color:transparent;
        background-clip:text;animation:shimmer 4s linear infinite;line-height:1.1;margin:8px 0 4px}}
.card{{background:linear-gradient(145deg,#13132a,#0d0d1f 50%,#13132a);border:1px solid var(--border);
       border-radius:20px;padding:40px 36px;position:relative;overflow:hidden;margin:24px 0;
       box-shadow:0 0 60px rgba(240,192,64,.06),inset 0 1px 0 rgba(255,255,255,.04)}}
.card::before,.card::after,.c3,.c4{{content:'';position:absolute;width:70px;height:70px;
  border-color:var(--gold2);border-style:solid;opacity:.3}}
.card::before{{top:14px;left:14px;border-width:2px 0 0 2px;border-radius:6px 0 0 0}}
.card::after{{bottom:14px;right:14px;border-width:0 2px 2px 0;border-radius:0 0 6px 0}}
.c3{{top:14px;right:14px;border-width:2px 2px 0 0;border-radius:0 6px 0 0}}
.c4{{bottom:14px;left:14px;border-width:0 0 2px 2px;border-radius:0 0 0 6px}}
.trophy{{font-size:68px;text-align:center;display:block;animation:float 3s ease-in-out infinite;
         filter:drop-shadow(0 0 20px rgba(240,192,64,.45));margin-bottom:16px}}
.hero{{font-family:'Cinzel Decorative',serif;font-size:clamp(22px,5vw,38px);text-align:center;
       color:var(--gold);text-shadow:0 0 30px rgba(240,192,64,.35);letter-spacing:1.5px;margin:8px 0 14px}}
.body-text{{text-align:center;font-size:16px;color:rgba(232,224,255,.78);line-height:1.7;
            font-style:italic;max-width:580px;margin:0 auto 26px}}
.body-text strong{{color:var(--gold);font-style:normal}}
.stats{{display:flex;justify-content:center;gap:14px;flex-wrap:wrap;margin-bottom:26px}}
.stat{{background:rgba(0,0,0,.32);border:1px solid var(--border);border-radius:12px;
       padding:12px 22px;text-align:center;min-width:100px}}
.stat-v{{font-family:'Cinzel Decorative',serif;font-size:26px;color:var(--gold);display:block}}
.stat-l{{font-family:'JetBrains Mono',monospace;font-size:9px;letter-spacing:2px;color:var(--dim);text-transform:uppercase}}
.chips{{display:flex;flex-wrap:wrap;justify-content:center;gap:7px;margin-bottom:26px}}
.chip{{display:flex;align-items:center;gap:6px;background:rgba(0,255,170,.04);
       border:1px solid rgba(0,255,170,.14);border-radius:8px;padding:6px 10px;
       font-size:12px;color:var(--green)}}
.divider{{height:1px;background:linear-gradient(90deg,transparent,var(--border),var(--gold2),var(--border),transparent);
          margin:26px 0;opacity:.7}}
.block-title{{text-align:center;font-family:'JetBrains Mono',monospace;font-size:10px;
              letter-spacing:5px;color:var(--purple);text-transform:uppercase;margin-bottom:14px}}
.block{{background:rgba(0,0,0,.45);border:1px solid #2a1f4e;border-radius:12px;padding:18px 20px;
        font-family:'JetBrains Mono',monospace;font-size:11px}}
.brow{{display:flex;gap:10px;margin-bottom:7px;flex-wrap:wrap}}
.bk{{color:var(--dim);min-width:100px;flex-shrink:0}}.bv{{color:var(--cyan);word-break:break-all}}
.bv.p{{color:var(--purple)}}.bv.g{{color:var(--green)}}
.badge{{display:flex;align-items:center;justify-content:center;gap:8px;margin-top:18px;
        padding:12px;background:rgba(0,255,170,.05);border:1px solid rgba(0,255,170,.2);
        border-radius:10px;font-family:'JetBrains Mono',monospace;font-size:10px;
        color:var(--green);letter-spacing:2px}}
.footer{{display:flex;justify-content:space-between;align-items:flex-end;
         margin-top:28px;padding-top:16px;border-top:1px solid var(--border);flex-wrap:wrap;gap:14px}}
.sig{{text-align:center}}.sig-line{{width:110px;height:1px;background:var(--gold2);
     margin:0 auto 5px;opacity:.45}}
.sig-lbl{{font-family:'JetBrains Mono',monospace;font-size:9px;letter-spacing:2px;color:var(--dim)}}
.date{{font-family:'JetBrains Mono',monospace;font-size:11px;color:var(--dim)}}
@media(max-width:600px){{.card{{padding:26px 18px}}.stats{{gap:10px}}}}
</style></head><body>
<div id="stars"></div>
<div class="page">
  <div class="lbl">⚔️ &nbsp; CodeQuest Academy &nbsp; ⚔️</div>
  <h1 class="title">Certificate of<br>Mastery</h1>
  <p class="lbl" style="letter-spacing:5px;margin-top:4px">Python Programming · Blockchain Verified</p>
  <div class="card">
    <div class="c3"></div><div class="c4"></div>
    <span class="trophy">🏆</span>
    <p class="lbl">This certifies that</p>
    <h2 class="hero">{name}</h2>
    <p class="body-text">has successfully completed the <strong>CodeQuest Python Adventure</strong>,
    mastering all <strong>13 core Python topics</strong> across two villages,
    and proven exceptional skill in the <strong>Grand Master Challenge</strong>.</p>
    <div class="stats">
      <div class="stat"><span class="stat-v">{xp}</span><span class="stat-l">Total XP</span></div>
      <div class="stat"><span class="stat-v">{count}</span><span class="stat-l">Quests</span></div>
      <div class="stat"><span class="stat-v">13</span><span class="stat-l">Topics</span></div>
    </div>
    <p class="lbl" style="margin-bottom:12px">✦ Topics Mastered ✦</p>
    <div class="chips">{chips}</div>
    <div class="divider"></div>
    <p class="block-title">⛓ &nbsp; Blockchain Verification &nbsp; ⛓</p>
    <div class="block">
      <div class="brow"><span class="bk">Block Index</span><span class="bv g">#{idx}</span></div>
      <div class="brow"><span class="bk">Issued At</span><span class="bv">{issued}</span></div>
      <div class="brow"><span class="bk">Recipient</span><span class="bv g">{name}</span></div>
      <div class="brow"><span class="bk">Prev Hash</span><span class="bv p">{prev[:32]}...</span></div>
      <div class="brow"><span class="bk">Cert Hash</span><span class="bv p">{h}</span></div>
    </div>
    <div class="badge">✓ &nbsp; CHAIN INTEGRITY VERIFIED &nbsp;·&nbsp; SHA-256 &nbsp;·&nbsp; TAMPER-PROOF</div>
    <div class="footer">
      <span class="date">Issued: {issued}</span>
      <div class="sig"><div class="sig-line"></div><div class="sig-lbl">CodeQuest Academy</div></div>
      <div class="sig"><div class="sig-line"></div><div class="sig-lbl">Course Director</div></div>
    </div>
  </div>
</div>
<script>
const s=document.getElementById('stars');
for(let i=0;i<110;i++){{
  const el=document.createElement('div');
  el.className='star';
  el.style.cssText=`left:${{Math.random()*100}}%;top:${{Math.random()*100}}%;
    --d:${{2+Math.random()*4}}s;--delay:${{Math.random()*5}}s;
    opacity:${{0.15+Math.random()*0.5}}`;
  s.appendChild(el);
}}
</script>
</body></html>"""
    return HTMLResponse(content=html)