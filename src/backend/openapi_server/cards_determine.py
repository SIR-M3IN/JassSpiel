from openapi_server.db import supabase

class Jasskarte:
    def __init__(self, cid: str):
        self.cid = cid

def get_card_type(cid: str) -> str:
    resp = supabase.table('card') \
                   .select('cardtype') \
                   .eq('CID', cid) \
                   .maybe_single() \
                   .execute()
    if not resp or resp.data is None:
        return ""
    return resp.data.get('cardtype', "")

def is_trumpf(cid: str, gid: str) -> bool:
    resp = supabase.table('cardingames') \
                   .select('isTrumpf') \
                   .eq('CID', cid) \
                   .eq('GID', gid) \
                   .maybe_single() \
                   .execute()
    if not resp or resp.data is None:
        return False
    return bool(resp.data.get('isTrumpf'))

def get_card_worth(cid: str, gid: str) -> int:
    if is_trumpf(cid, gid):
        return {"Ass":19,"König":18,"Ober":17,"Unter":16,"10":15,"9":14,"8":13,"7":12,"6":11}.get(get_card_type(cid),0)
    return {"Ass":9,"König":8,"Ober":7,"Unter":6,"10":5,"9":4,"8":3,"7":2,"6":1}.get(get_card_type(cid),0)

def get_winning_card(cards: list[Jasskarte], gid: str) -> str:
    best, best_w = None, -1
    for c in cards:
        w = get_card_worth(c.cid, gid)
        if w > best_w:
            best_w, best = w, c
    if not best:
        return ""
    resp = supabase.table('cardingames') \
                   .select('UID') \
                   .eq('CID', best.cid) \
                   .eq('GID', gid) \
                   .maybe_single() \
                   .execute()
    if not resp or resp.data is None:
        return ""
    return resp.data.get('UID', "")