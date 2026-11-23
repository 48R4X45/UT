// WeaponPrefs: per-range weapon priority lists (stock UT2004 weapon class names).
class WeaponPrefs extends Object;

// Returns a '|'-separated priority list for the given distance (UU).
static function string ListForRange(float Dist)
{
    if (Dist < 700.0)    // close: flak, shock, bio, assault
        return "XWeapons.FlakCannon|XWeapons.ShockRifle|XWeapons.BioRifle|XWeapons.AssaultRifle";
    if (Dist < 2200.0)   // mid: shock, rockets, link, flak
        return "XWeapons.ShockRifle|XWeapons.RocketLauncher|XWeapons.LinkGun|XWeapons.FlakCannon";
    // far: classic sniper, lightning gun (XWeapons.SniperRifle), shock, minigun
    return "UTClassic.ClassicSniperRifle|XWeapons.SniperRifle|XWeapons.ShockRifle|XWeapons.Minigun";
}

// Finds the first weapon in P's inventory that matches the range list and has ammo.
static function Weapon PickWeapon(Pawn P, float Dist)
{
    local array<string> Names;
    local Inventory Inv;
    local Weapon W;
    local int i;

    if (P == None)
        return None;

    Split(ListForRange(Dist), "|", Names);
    for (i = 0; i < Names.Length; i++)
    {
        for (Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
        {
            W = Weapon(Inv);
            if (W != None && string(W.Class) ~= Names[i] && W.HasAmmo())
                return W;
        }
    }
    return None;
}

defaultproperties
{
}
