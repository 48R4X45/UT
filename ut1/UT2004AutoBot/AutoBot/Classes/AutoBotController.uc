// AutoBotController: custom utility-scored bot brain extending stock xBot.
// Uses Tick accumulation instead of SetTimer/Timer() so stock Bot state timers
// (Hunting, TacticalMove, StakeOut, RangedAttack, Fallback) are never clobbered.
// Offline use only: refuses to run unless the game is standalone.
class AutoBotController extends xBot config(AutoBot);

var config float RetreatHealth;     // below this, prefer Retreat
var config float WeightFight;
var config float WeightGrabItem;
var config float WeightRoam;
var config float WeightRetreat;
var config float ThinkInterval;
var config bool  bDebugLog;

var name  BrainState;               // Fight / Roam / GrabItem / Retreat
var name  PrevBrainState;
var float ThinkAccum;
var bool  bIsAutoPlay;              // true when driving a human player's pawn
var bool  bPreservePawnAppearance;  // skip xPawn.Setup(PawnSetupRecord) on Possess

function PostBeginPlay()
{
    Super.PostBeginPlay();
    if (Level.NetMode != NM_Standalone)
    {
        Log("AutoBotController: refusing to run outside standalone games.");
        Destroy();
        return;
    }
}

function Possess(Pawn aPawn)
{
    if (bPreservePawnAppearance || bIsAutoPlay)
        Super(Bot).Possess(aPawn);
    else
        Super.Possess(aPawn);
}

function Destroyed()
{
    if (Squad != None)
        Squad.RemoveBot(self);
    if (GoalScript != None)
        GoalScript.FreeScript();
    Super(ScriptedController).Destroyed();
}

function float ScoreFight()
{
    if (Enemy == None || Pawn == None)
        return 0.0;
    return WeightFight * (float(Pawn.Health) / 100.0)
         * FClamp(1.0 - VSize(Enemy.Location - Pawn.Location) / 3000.0, 0.1, 1.0);
}

function float ScoreRetreat()
{
    if (Enemy == None || Pawn == None || RetreatHealth <= 0.0 || Pawn.Health >= RetreatHealth)
        return 0.0;
    return WeightRetreat * (1.0 - float(Pawn.Health) / RetreatHealth);
}

function float ScoreGrabItem()
{
    local float Score;

    if (Pawn == None)
        return 0.0;

    Score = WeightGrabItem * FClamp(1.0 - float(Pawn.Health) / 150.0, 0.0, 1.0);
    if (Enemy == None)
        Score += 0.3;
    return Score;
}

function PickRangeWeapon()
{
    local Weapon W;

    if (Pawn == None || Enemy == None)
        return;
    if (Pawn.Weapon != None && Pawn.Weapon.IsFiring())
        return;

    W = class'WeaponPrefs'.static.PickWeapon(Pawn, VSize(Enemy.Location - Pawn.Location));
    if (W == None)
        SwitchToBestWeapon();
    else if (W != Pawn.Weapon && W != Pawn.PendingWeapon)
    {
        Pawn.PendingWeapon = W;
        if (Pawn.Weapon != None)
            Pawn.Weapon.PutDown();
        else
            Pawn.ChangedWeapon();
    }
}

function RunBrainThink()
{
    local float f, r, g, w, best;

    if (Pawn == None || Pawn.Health <= 0)
        return;

    f = ScoreFight();
    r = ScoreRetreat();
    g = ScoreGrabItem();
    w = WeightRoam * 0.2;

    best = FMax(FMax(f, r), FMax(g, w));
    if (best == r && r > 0.0)       BrainState = 'Retreat';
    else if (best == f && f > 0.0)  BrainState = 'Fight';
    else if (best == g)             BrainState = 'GrabItem';
    else                            BrainState = 'Roam';

    if (bDebugLog && BrainState != PrevBrainState)
    {
        Log("AutoBotController[" $ GetHumanReadableName() $ "]: "
            $ PrevBrainState $ " -> " $ BrainState
            $ " (HP=" $ Pawn.Health $ " F=" $ f $ " R=" $ r $ " G=" $ g $ ")");
    }

    switch (BrainState)
    {
        case 'Retreat':
            CombatStyle = -1.0;
            if (Squad != None && !IsInState('Retreating') && !IsInState('Fallback'))
                DoRetreat();
            break;

        case 'Fight':
            CombatStyle = 0.6;
            PickRangeWeapon();
            break;

        case 'GrabItem':
        case 'Roam':
            CombatStyle = 0.0;
            if (Enemy == None && Squad != None && (MoveTarget == None || BrainState != PrevBrainState))
                WhatToDoNext(12);
            break;
    }

    PrevBrainState = BrainState;
}

event Tick(float DeltaTime)
{
    Super.Tick(DeltaTime);

    if (Pawn == None || Pawn.Health <= 0 || IsInState('Dead') || IsInState('GameEnded'))
        return;

    ThinkAccum += DeltaTime;
    if (ThinkAccum < FMax(ThinkInterval, 0.1))
        return;

    ThinkAccum = 0.0;
    RunBrainThink();
}

defaultproperties
{
    RetreatHealth=40.0
    WeightFight=1.0
    WeightGrabItem=0.8
    WeightRoam=0.5
    WeightRetreat=1.5
    ThinkInterval=0.5
    bDebugLog=False
}
