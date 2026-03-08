import json, subprocess

def electrum_rpc(*args: str):
    cmd = ["electrum"] + list(args)
    out = subprocess.check_output(cmd, text=True)
    return json.loads(out)

def get_balance():
    return electrum_rpc("getbalance")
