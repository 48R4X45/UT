// AutoBotSwapMutator: gives every botmatch bot the AutoBotController brain.
// Primary path: overrides xPawn.default.ControllerClass in PreBeginPlay so
// DeathMatch.SpawnBot() natively spawns AutoBotController with full PRI,
// Squad, Team, RosterEntry stats, and PawnSetupRecord, then restores it on Destroyed.
// Fallback path: safely swaps any stock Bot that already existed or used another PawnClass.
class AutoBotSwapMutator extends Mutator;

var class<AIController> SavedXPawnControllerClass;

function PreBeginPlay()
{
    Super.PreBeginPlay();
    if (Level.NetMode != NM_Standalone)
        return;

    if (class'xPawn'.default.ControllerClass != class'AutoBotController')
    {
        SavedXPawnControllerClass = class'xPawn'.default.ControllerClass;
        class'xPawn'.default.ControllerClass = class'AutoBotController';
    }
}

function PostBeginPlay()
{
    Super.PostBeginPlay();
    if (Level.NetMode != NM_Standalone)
        return;
    SetTimer(1.0, true);
}

function Destroyed()
{
    if (SavedXPawnControllerClass != None)
    {
        class'xPawn'.default.ControllerClass = SavedXPawnControllerClass;
        SavedXPawnControllerClass = None;
    }
    Super.Destroyed();
}

function Timer()
{
    local Controller C;
    local Bot B;
    local xBot XB;
    local AutoBotController Brain;
    local Pawn P;
    local SquadAI OldSquad;
    local DMSquad NewDMSquad;

    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        B = Bot(C);
        if (B == None || AutoBotController(C) != None || B.Pawn == None)
            continue;

        P = B.Pawn;
        Brain = Spawn(class'AutoBotController');
        if (Brain == None)
            continue;

        // Discard Brain's auto-spawned PRI to avoid ghost scoreboard entries.
        if (Brain.PlayerReplicationInfo != None)
        {
            Brain.PlayerReplicationInfo.Destroy();
            Brain.PlayerReplicationInfo = None;
        }

        // Transfer PRI and ownership.
        Brain.PlayerReplicationInfo = B.PlayerReplicationInfo;
        if (Brain.PlayerReplicationInfo != None)
            Brain.PlayerReplicationInfo.SetOwner(Brain);
        B.PlayerReplicationInfo = None;

        // Preserve bot stats and appearance.
        Brain.bPreservePawnAppearance = true;
        Brain.Skill              = B.Skill;
        Brain.Accuracy           = B.Accuracy;
        Brain.StrafingAbility    = B.StrafingAbility;
        Brain.CombatStyle        = B.CombatStyle;
        Brain.Aggressiveness     = B.Aggressiveness;
        Brain.BaseAggressiveness = B.BaseAggressiveness;
        Brain.Tactics            = B.Tactics;
        Brain.ReactionTime       = B.ReactionTime;
        Brain.Jumpiness          = B.Jumpiness;
        Brain.FavoriteWeapon     = B.FavoriteWeapon;
        Brain.PawnClass          = B.PawnClass;
        Brain.StartSpot          = B.StartSpot;

        XB = xBot(B);
        if (XB != None)
            Brain.PawnSetupRecord = XB.PawnSetupRecord;

        // Transfer Squad safely: DMSquad.RemoveBot destroys the DMSquad, so spawn a fresh one in DM.
        OldSquad = B.Squad;
        if (DMSquad(OldSquad) != None || OldSquad == None)
        {
            NewDMSquad = Spawn(class'DMSquad');
            if (NewDMSquad != None)
                NewDMSquad.AddBot(Brain);
        }
        else
        {
            OldSquad.AddBot(Brain);
        }

        // Prevent B.Destroy() from calling Level.Game.Logout(B) and spawning a replacement bot.
        B.bIsPlayer = false;
        B.UnPossess();
        Brain.Possess(P);
        B.Destroy();
        Brain.WhatToDoNext(0);
        return;     // one swap per tick keeps ControllerList iteration safe
    }
}

defaultproperties
{
    FriendlyName="AutoBot Brain"
    Description="Replaces stock bot brains with AutoBotController (offline only)."
    GroupName="AutoBotBrain"
}
