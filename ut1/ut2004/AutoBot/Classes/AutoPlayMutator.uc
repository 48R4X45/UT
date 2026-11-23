// AutoPlayMutator: toggle autopilot for YOUR character in offline games.
// Bind a key in console:  set Input F8 mutate AutoPlay
class AutoPlayMutator extends Mutator;

var PlayerController  SavedPC;
var AutoBotController Brain;
var DMSquad           AutoPlaySquad;

function Mutate(string MutateString, PlayerController Sender)
{
    if (MutateString ~= "AutoPlay")
        Toggle(Sender);
    Super.Mutate(MutateString, Sender);
}

function Toggle(PlayerController PC)
{
    if (PC == None)
        return;

    if (Level.NetMode != NM_Standalone)
    {
        PC.ClientMessage("AutoPlay is only available in standalone (offline) games.");
        return;
    }

    if (Brain == None)
        EnableAutoPlay(PC);
    else
        DisableAutoPlay();
}

function EnableAutoPlay(PlayerController PC)
{
    local Pawn P;
    local UnrealTeamInfo TeamInfo;
    local DeathMatch DM;

    if (PC == None || PC.PlayerReplicationInfo == None || PC.PlayerReplicationInfo.bOnlySpectator)
        return;

    P = PC.Pawn;
    if (P == None || P.Health <= 0)
    {
        PC.ClientMessage("AutoPlay requires a living pawn.");
        return;
    }

    SavedPC = PC;
    Brain = Spawn(class'AutoBotController');
    if (Brain == None)
        return;

    Brain.bIsAutoPlay = true;
    Brain.bPreservePawnAppearance = true;

    // Discard Brain's auto-created PRI so no ghost bot appears on the scoreboard,
    // then share the human player's PRI so kills/team belong to the human player.
    if (Brain.PlayerReplicationInfo != None)
    {
        Brain.PlayerReplicationInfo.Destroy();
        Brain.PlayerReplicationInfo = None;
    }
    Brain.PlayerReplicationInfo = PC.PlayerReplicationInfo;

    DM = DeathMatch(Level.Game);
    if (DM != None)
        Brain.InitializeSkill(DM.AdjustedDifficulty);
    else
        Brain.InitializeSkill(4.0);

    // Ensure Brain has a valid Squad (required by stock Bot AI & Retreat/Fallback).
    if (Level.Game.bTeamGame && PC.PlayerReplicationInfo.Team != None)
    {
        TeamInfo = UnrealTeamInfo(PC.PlayerReplicationInfo.Team);
        if (TeamInfo != None && TeamInfo.AI != None)
            TeamInfo.AI.SetBotOrders(Brain, None);
    }
    if (Brain.Squad == None)
    {
        AutoPlaySquad = Spawn(class'DMSquad');
        if (AutoPlaySquad != None)
            AutoPlaySquad.AddBot(Brain);
    }

    PC.UnPossess();
    Brain.Possess(P);
    Brain.WhatToDoNext(0);
    PC.SetViewTarget(P);
    PC.ClientMessage("AutoPlay ON");
    SetTimer(0.25, true);           // watch for death or match end
}

function DisableAutoPlay()
{
    local Pawn P;

    SetTimer(0.0, false);

    if (Brain != None)
    {
        P = Brain.Pawn;
        Brain.StopFiring();
        Brain.UnPossess();
        if (Brain.Squad != None)
            Brain.Squad.RemoveBot(Brain);
        // Detach human PRI and clear bIsPlayer BEFORE Destroy() so human's PRI
        // is not destroyed and DeathMatch.Logout() is not triggered.
        Brain.PlayerReplicationInfo = None;
        Brain.bIsPlayer = false;
        Brain.Destroy();
        Brain = None;
    }

    if (AutoPlaySquad != None && !AutoPlaySquad.bDeleteMe)
    {
        AutoPlaySquad.Destroy();
        AutoPlaySquad = None;
    }

    if (SavedPC != None)
    {
        if (P != None && P.Health > 0)
        {
            SavedPC.Possess(P);
            SavedPC.SetViewTarget(P);
        }
        else
        {
            SavedPC.SetViewTarget(SavedPC);
            if (!SavedPC.IsInState('Dead') && !SavedPC.IsInState('GameEnded'))
                SavedPC.GotoState('Dead');
        }
        SavedPC.ClientMessage("AutoPlay OFF");
        SavedPC = None;
    }
}

function Timer()
{
    if (Brain == None)
    {
        SetTimer(0.0, false);
        return;
    }

    // Pawn died or game ended: return control to human so respawn/end works normally.
    if (Brain.Pawn == None || Brain.Pawn.Health <= 0 || Level.Game.bGameEnded)
        DisableAutoPlay();
}

function Destroyed()
{
    if (Brain != None)
        DisableAutoPlay();
    Super.Destroyed();
}

defaultproperties
{
    FriendlyName="AutoPlay"
    Description="Press the bound key to let AutoBotController play your character (offline only)."
    GroupName="AutoPlay"
}
