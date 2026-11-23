// AutoBotMutator: tunes every stock Bot in the match (skill, aggression,
// strafing, accuracy, jumpiness, projectile leading, low-health retreat bias).
// Offline / local botmatch use only.
class AutoBotMutator extends Mutator config(AutoBot);

var config float BotSkill;          // 0..7
var config float Aggression;        // -1..1 (CombatStyle)
var config float StrafeAbility;     // -1..1
var config float AccuracyBonus;     // -1..1
var config bool  bHuntItems;        // retreat / hunt items at low health
var config float TuneInterval;      // seconds between re-tunes

function PostBeginPlay()
{
    Super.PostBeginPlay();
    if (Level.NetMode != NM_Standalone)
    {
        Log("AutoBotMutator: refusing to run outside standalone games.");
        return;
    }
    SetTimer(FMax(TuneInterval, 0.2), true);
}

function Timer()
{
    local Controller C;
    local Bot B;

    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        B = Bot(C);
        if (B == None || B.Pawn == None)
            continue;

        B.Skill           = FClamp(BotSkill, 0.0, 7.0);
        B.Accuracy        = FClamp(AccuracyBonus, -1.0, 1.0);
        B.StrafingAbility = FClamp(StrafeAbility, -1.0, 1.0);
        B.Jumpiness       = 0.5;
        B.bLeadTarget     = true;

        // AutoBotController manages its own dynamic CombatStyle and range weapons.
        if (AutoBotController(B) != None)
            continue;

        if (bHuntItems && B.Pawn.Health < 40 && B.Enemy != None && B.Pawn.Health < B.Enemy.Health)
            B.CombatStyle = -1.0;
        else
            B.CombatStyle = FClamp(Aggression, -1.0, 1.0);

        if (B.Pawn.Weapon == None || !B.Pawn.Weapon.IsFiring())
            B.SwitchToBestWeapon();
    }
}

defaultproperties
{
    FriendlyName="AutoBot"
    Description="Tunes stock bot skill, aggression, strafing, accuracy, and item hunting (offline only)."
    GroupName="AutoBotTune"
    BotSkill=6.0
    Aggression=0.6
    StrafeAbility=0.8
    AccuracyBonus=0.5
    bHuntItems=True
    TuneInterval=1.0
}
