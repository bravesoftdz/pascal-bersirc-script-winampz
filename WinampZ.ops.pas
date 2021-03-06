{ WinampZ front end to WinampAPI.ops

  Put all files in the Scripts directory and add WinampZ
  near the top of Bersirc.ops on the 'uses' line, eg:

    uses Extras, Events, Menus, Nickcomp, WinampZ;

  The following are the 'simple' WinampZ commands.
  Try them all with Winamp both closed and open.

    /song, /songa, /rand, /open, /send <nick>
  
  Most commands are provided in a more cryptic z form.
  The following do the same as the simple ones above.
  
    /z,    /za,    /zr,   /zz,   /zs <nick>
  
  There are more z functions, like /zget & whatever is
  added in the future. These are what I use personally.
  The 'simple' wrappers are there for casual users, and
  as a quick way to customize.
    
  Additionally initial support has been added to allow
  people to /ctcp <yournick> !ZGET for song dcc's. This
  behaviour is configurable with WZ_GET* constants below.
  ZGET functionality is disabled by default. /songa & /za
  will enabled ZGET, and /zget toggles it on and off.
  
  Experiment with some WinampAPI.ops procedures directly
  eg. /WA_TrackStopFade, /WA_ToggleAlwaysOnTop, /WA_Restart
  See WinampAPI.txt & WinampAPI.ops for more information

  The power is in WinampAPI.ops, this script is just an
  example using that power. Contributions to this script
  using WinampAPI.ops are welcome.

}

unit WinampZ;

uses WinampAPI;

const
  WZ_GET_ALLOW     = 0; // Allows people to /ctcp yournick !zget
  WZ_GET_ADVERTISE = 0; // Advertises !zget capabilities in /song

// WinampK/newbie compatible wrappers
procedure song;  begin z  end;
procedure songa; begin za end;
procedure rand;  begin zr end;
procedure open;  begin zz end;
procedure send(Nick: String); begin zs(Nick) end;

// Output wrappers
procedure WZ_Output(Text: String);
begin
  Act(Text);
end;

procedure WZ_OutputInfo(Text: String);
begin
  Echo(GetBCol(bcInfo), nil, '', '* WinampZ * ' + Text, CurServer);
end;

// Z commands, preferred
// Outputs current track information
procedure z;
var
  c1,c2,c3,c4,c5,lenstr,getstr: string;
  len: integer;
begin
  if (WA_IsReady) then
  begin
    c1 := ' (';
    c2 := ')';
    c3 := ' [';
    c4 := ']';
    c5 := '/';
    
    if (WZ_GET_ADVERTISE = 1) then
      getstr := c3+'/ctcp '+Me+' !ZGET'+c4;

    WZ_Output('is listening to: '+
      WA_GetTitle+
      c1+WA_ms2str(WA_GetTrackPosition)+c5+WA_sec2str(WA_GetTrackLength)+c2+
      c3+IntToStr(WA_GetPlaylistIndex)+c5+IntToStr(WA_GetPlaylistCount)+c4+
      c3+IntToStr(WA_GetTrackBitrate)+'Kbps'+c4+
//      c3+IntToStr(WA_GetTrackSampleRate)+'KHz'+c4+
      c3+IntToStr(WA_GetTrackFileSize/1024)+'Kb'+c4+
      getstr
    );
  end
  else
  begin
    if (WA_IsRunning) then
      WZ_OutputInfo('Winamp is not playing')
    else
      WZ_OutputInfo('Winamp is not running');
  end;
end;

// same as z, but forces advertising and enables zget if necessary
procedure za;
begin
  if (WZ_GET_ALLOW = 0) then
  begin
    WZ_GET_ALLOW := 1;
    WZ_OutputInfo('ZGET Enabled');
  end;
  
  if (WZ_GET_ADVERTISE = 0) then
  begin
    WZ_GET_ADVERTISE := 1;
    z;
    WZ_GET_ADVERTISE := 0;
  end
  else
    z;
end;

// Random Play
procedure zr;
var oldShuffle: boolean;
begin
  // open winamp if it is not already
  if (WA_IsRunning = 0) then
  begin
    WA_Start;
    Sleep(WA_DELAY_START);
  end;
  
  // do the shuffle
  oldShuffle := WA_GetShuffle;
  if (WA_GetShuffle = 0) then
    WA_SetShuffle(true);
  WA_TrackNext;
  WZ_OutputInfo('Randomized to ['+WA_GetTitle+']');
  WA_SetShuffle(oldShuffle);
  
  // start playing, necessary when winamp was closed or not playing
  WA_TrackPlay;
end;

// DCC current track to specified nick
procedure zs(Nick: String);
begin
  // HAX (1.34.909) : DCCSend errors when comma in filename and no nick
  if (WA_IsRunning) then
    DCCSend(CurServer,Nick,WA_GetTrackFile)
  else
    WZ_OutputInfo('Winamp is not running');
end;

// Open winamp file dialog
procedure zz;
begin
  WA_Activate;
  WA_OpenFileDialog;
end;

// Toggle ZGET via WZ_GET_ALLOW
procedure zget;
begin
  if (WZ_GET_ALLOW = 0) then
  begin
    WZ_GET_ALLOW := 1;
    WZ_OutputInfo('ZGET Enabled');
  end
  else
  begin
    WZ_GET_ALLOW := 0;
    WZ_OutputInfo('ZGET Disabled');    
  end;
end;

// Events

// TODO : more security options. nick has to be in same channel? limit requests per nick, etc...
//        How do you know when slots are free?
procedure OnCTCPQuery(ServerID: Integer; Nick, Channel, Command, Arguments: String);
var f: String;
begin

  if (WZ_GET_ALLOW = 1) then
    if (command = '!ZGET') then
    begin
      f := WA_GetTrackFile;
      if (f = '') then Exit;
      
      WZ_OutputInfo('Sending current track to '+ Nick +' ['+f+']');
      DCCSend(curserver,nick,f);
    end;

end;

end.
