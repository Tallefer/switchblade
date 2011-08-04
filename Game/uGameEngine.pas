unit uGameEngine;

interface

uses
  Windows, SysUtils, Forms, Classes, Controls, Graphics, Dialogs, Messages,

  jpeg, GLFilePNG, GLFileJPEG, GLFileDDS,

  GLBitmapFont, GLWindowsFont, GLCadencer, GLMaterial, GLMaterialEx, GLScene, GLObjects, GLCoordinates, GLCrossPlatform, BaseClasses, GLWin32Viewer, GLHUDObjects,
  GLColor, GLRenderContextInfo, AsyncTimer, VectorGeometry, VectorTypes,

  NativeXml, uGameIntro, uGameMenu, uGUIElements, uOptions, uCommonFuncProc;

type
  TPaths = record
    EXE,
    Textures,
    Sounds,
    Models,
    Saves: string;
  end;

  TGameState = (gsNone, gsIntro, gsTiters, gsOptions, gsPause, gsRun);

  TGameEngine = class(TGLScene)
  private
    FButtonClose, FButtonMinimize, FButtonMainMenu: TGUIButton;
    AsyncTimer:   TAsyncTimer;
    FFPSText,
    AVersionText: TGLHUDText;
    FLastCurPos,
    FCurPos:      TPoint;
    FMainForm:    TForm;
    FCadencer:    TGLCadencer;
    FViewer:      TGLSceneViewer;
    FWinFont:     TGLWindowsBitmapFont;
    FGUIElements: TGLDummyCube;

    FPaths:       TPaths;
    FGameState:   TGameState;

    FIsGameStarted, FCanClose: boolean;

    function GetCamera: TGLCamera;
    procedure ApplyOptions;

    // ���������� ��� ������� � ����
    procedure OnFormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OnViewerClick(Sender: TObject);
    procedure OnViewerDblClick(Sender: TObject);
    procedure OnFormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnFormKeyPress(Sender: TObject; var Key: Char);
    procedure OnFormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnViewerMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure OnViewerMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure OnViewerMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure OnViewerMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure OnViewerMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure OnViewerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);

    procedure OnCadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
    procedure OnAsyncTimer(Sender: TObject);
    procedure OnEndIntro(Sender: TObject);

    procedure OnGameMenuItemClick(AGameMenuItem: TGameMenuItem);
    procedure OnGameMenuItemDblClick(AGameMenuItem: TGameMenuItem);
    procedure OnGameMenuItemEnter(AGameMenuItem: TGameMenuItem);
    procedure OnGameMenuItemLeave(AGameMenuItem: TGameMenuItem);
    procedure OnGameMenuShow(AGameMenu: TGameMenu);

    procedure OnGUISystemButtonClick(AButton: TGUIButton);
    procedure OnGUISystemButtonEnter(AButton: TGUIButton);
    procedure OnGUISystemButtonLeave(AButton: TGUIButton);

    procedure CreateMainMenu;
    procedure CreateYesNoMenu;
    procedure CreateOptionsMenu;
    procedure CreateSystemMenuButtons;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetTextWidth(AText: string; AFont: TFont = nil): integer;
    function GetTextHeight(AText: string; AFont: TFont = nil): integer;

    procedure LoadGame;
    procedure SaveGame;
    procedure ResumeGame;
    procedure StartNewGame;
    procedure PauseGame;
    procedure ExitGame;
    procedure ShowIntro;
    procedure ShowTiters;
    procedure ShowOptions;
  published
    property MainForm:      TForm          read FMainForm;
    property Cadencer:      TGLCadencer    read FCadencer;
    property Viewer:        TGLSceneViewer read FViewer;
    property Camera:        TGLCamera      read GetCamera;
    property Paths:         TPaths         read FPaths;
    property GameState:     TGameState     read FGameState;
    property IsGameStarted: boolean        read FIsGameStarted;

    property LastCurPos: TPoint            read FLastCurPos;
    property CurPos: TPoint                read FCurPos;
  end;

var
  FGameEngine: TGameEngine;

const
  CAPTION_MAIN_FORM      = 'SwithBlade';
  //MESS_FONT_FILE_NAME = 'gost.ttf';
  //MESS_FONT_NAME = 'GOST type A';

  MESS_FONT_FILE_NAME    = 'EurostileExt-Reg.otf';
  MESS_FONT_NAME         = 'EurostileExtReg';
  CAPTION_FONT_FILE_NAME = 'EurostileExt-Med.otf';
  CAPTION_FONT_NAME      = 'EurostileExtMed';
  FORM_WIDTH  = 1024;
  FORM_HEIGHT = 768;

  CAPTION_MAIN_MENU      = '������� ����';
  CAPTION_EXIT_GAME      = '����� �� ���� ?';
  CAPTION_START_NEW_GAME = '������ ����� ���� ?';
  CAPTION_OPTIONS_GAME   = '��������� ����';
  CAPTION_APPLY_OPTIONS  = '��������� ��������� ?';

  BUTTON_NAME_CLOSE      = 'btnClose';
  PIC_FILE_BTN_CLOSE     = 'close.png';
  BUTTON_NAME_MINIMIZE   = 'btnMinimize';
  PIC_FILE_BTN_MINIMIZE  = 'minimize.png';
  BUTTON_NAME_MAIN_MENU  = 'btnMainMenu';
  PIC_FILE_BTN_MAIN_MENU = 'mainmenu.png';

implementation

uses uMain, uLog;

{ TGameEngine }

procedure TGameEngine.ApplyOptions;
begin
  // ��������� ��������� ����

end;

constructor TGameEngine.Create(AOwner: TComponent);
begin
  inherited;
  Application.Title:= CAPTION_MAIN_FORM;
  FCanClose:= false;
  Randomize;
  // ����
  with FPaths do begin
    EXE:=      ExtractFilePath(ParamStr(0));
    Textures:= EXE + 'textures\';
    Sounds:=   EXE + 'sounds\';
    Models:=   EXE + 'models\';
    Saves:=    EXE + 'saves\';
  end;

  if not DirectoryExists(FPaths.Saves) then
    CreateDir(FPaths.Saves);

  // ��������� �����������
  FGameState:=     gsNone;
  FIsGameStarted:= false;

  // ��������� ��� ��.����� - ���������, ������, ���_������ � ����������� �� �������
  FMainForm:=             Application.MainForm;
  MainForm.BorderStyle:=  bsNone;
  MainForm.Width:=        FORM_WIDTH;
  MainForm.Height:=       FORM_HEIGHT;
  MainForm.Left:=         (Screen.Width  - FORM_WIDTH)  div 2;
  MainForm.Top:=          (Screen.Height - FORM_HEIGHT) div 2;
  MainForm.KeyPreview:=   true;
  MainForm.OnKeyDown:=    OnFormKeyDown;
  MainForm.OnKeyPress:=   OnFormKeyPress;
  MainForm.OnKeyUp:=      OnFormKeyUp;
  MainForm.OnCloseQuery:= OnFormCloseQuery;
  MainForm.Caption:=      CAPTION_MAIN_FORM;

  // ��������
  FCadencer:=            TGLCadencer.Create(self);
  Cadencer.OnProgress:=  OnCadencerProgress;
  Cadencer.Scene:=       self;
  Cadencer.Enabled:=     false;
  Cadencer.SleepLength:= -1;

  // ����� � ��� ����������� ����, ����, ����� � �.�.; ������
  FViewer:=                       TGLSceneViewer.Create(self);
  Viewer.Parent:=                 MainForm;
  Viewer.Camera:=                 TGLCamera(Objects.AddNewChild(TGLCamera));
  Viewer.Align:=                  alClient;
  Viewer.Buffer.BackgroundColor:= clBlack;
  Viewer.Buffer.ContextOptions:=  [roDoubleBuffer, roStencilBuffer, roRenderToWindow];
  Viewer.OnMouseDown:=            OnViewerMouseDown;
  Viewer.OnMouseUp:=              OnViewerMouseUp;
  Viewer.OnMouseWheel:=           OnViewerMouseWheel;
  Viewer.OnMouseWheelDown:=       OnViewerMouseWheelDown;
  Viewer.OnMouseWheelUp:=         OnViewerMouseWheelUp;
  Viewer.OnMouseMove:=            OnViewerMouseMove;
  Viewer.OnClick:=                OnViewerClick;
  Viewer.OnDblClick:=             OnViewerDblClick;

  // ����� ��� ��������� ����������
  if FileExists(Paths.Textures + MESS_FONT_FILE_NAME) then begin
    AddFontResource(pchar(Paths.Textures + MESS_FONT_FILE_NAME));
    SendMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);
  end;

  // ����� ��� ��������� �������
  if FileExists(Paths.Textures + CAPTION_FONT_FILE_NAME) then begin
    AddFontResource(pchar(Paths.Textures + CAPTION_FONT_FILE_NAME));
    SendMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);
  end;

  FWinFont:= TGLWindowsBitmapFont.Create(self);
  with FWinFont do begin
    Font.Charset:= 204; // RUSSIAN_CHARSET
    Font.Name:=    MESS_FONT_NAME;
    Font.Size:=    6;
    Font.Quality:= fqClearType;
    Ranges.Clear;
    with Ranges.Add do begin
      StartASCII:= #32;
      StopASCII:=  #122;
    end;
    with Ranges.Add do begin
      StartASCII:= #1040;
      StopASCII:=  #1103;
    end;
    VSpace:= 0;
    HSpace:= 0;
  end;

  // ��� ����
  //Application.CreateForm(TfmLog, fmLog);
  //fmLog.Show;

  // �������� ����
  ShowIntro;
  FGUIElements:= TGLDummyCube(Objects.AddNewChild(TGLDummyCube));

  FFPSText:=            TGLHUDText(Self.Objects.AddNewChild(TGLHUDText));
  FFPSText.BitmapFont:= FWinFont;

  // �������� ������ �����
  AVersionText:=            TGLHUDText(Self.Objects.AddNewChild(TGLHUDText));
  AVersionText.BitmapFont:= FWinFont;
  AVersionText.Text:=       GetVersionFile(ParamStr(0));
  if AVersionText.Text <> '' then begin
    AVersionText.Text:= 'v' + AVersionText.Text;
    AVersionText.Position.SetPoint(MainForm.Width - 2 - GetTextWidth(AVersionText.Text), MainForm.Height - GetTextHeight(AVersionText.Text), 0);
  end else
    FreeAndNil(AVersionText);

  AsyncTimer:=                TAsyncTimer.Create(self);
  AsyncTimer.Interval:=       500;
  AsyncTimer.OnTimer:=        OnAsyncTimer;
  AsyncTimer.ThreadPriority:= tpLowest;
  AsyncTimer.Enabled:=        true;
end;

destructor TGameEngine.Destroy;
begin
  // ���������� ��� ��� ���������
  FCadencer.Enabled:= false;
  Objects.DeleteChildren;
  FreeAndNil(FCadencer);
  FreeAndNil(FViewer);
  FreeAndNil(FWinFont);
  if FileExists(Paths.Textures + MESS_FONT_FILE_NAME) then begin
    RemoveFontResource(pchar(Paths.Textures + MESS_FONT_FILE_NAME));
    SendMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);
  end;
  if FileExists(Paths.Textures + CAPTION_FONT_FILE_NAME) then begin
    RemoveFontResource(pchar(Paths.Textures + CAPTION_FONT_FILE_NAME));
    SendMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);
  end;
  inherited;
end;

procedure TGameEngine.ExitGame;
begin
  // ����� �� ����
  FCanClose:= true;
  FMainForm.Visible:= false;
  FGameState:= gsNone;
  FIsGameStarted:= false;
  FMainForm.Close;
end;

function TGameEngine.GetCamera: TGLCamera;
begin
  // �������� ������
  Result:= nil;
  if Assigned(FViewer) then
    Result:= FViewer.Camera;
end;

function TGameEngine.GetTextHeight(AText: string; AFont: TFont): integer;
begin
  // �������� ������ ������ � ��������
  if Assigned(MainForm) and (AText <> '') then begin
    if Assigned(AFont) then
      MainForm.Canvas.Font.Assign(AFont)
    else
      MainForm.Canvas.Font.Assign(FWinFont.Font);
    Result:= MainForm.Canvas.TextHeight(AText);
  end else
    Result:= -1;
end;

function TGameEngine.GetTextWidth(AText: string; AFont: TFont): integer;
begin
  // �������� ������ ������ � ��������
  if Assigned(MainForm) and (AText <> '') then begin
    if Assigned(AFont) then
      MainForm.Canvas.Font.Assign(AFont)
    else
      MainForm.Canvas.Font.Assign(FWinFont.Font);
    Result:= MainForm.Canvas.TextWidth(AText);
  end else
    Result:= -1;
end;

procedure TGameEngine.LoadGame;
begin
  // ��������� ����
  FGameState:= gsPause;
  FCadencer.Enabled:= false;
  try
    with TOpenDialog.Create(self) do try
      Title:=      '�������� ���� ��� ��������';
      InitialDir:= FPaths.Saves;
      DefaultExt:= '.sav';
      Filter:=     '����� ���������� (*.sav)|*.sav';
      Options:= Options + [ofFileMustExist];
      if Execute(MainForm.Handle) then begin
        FIsGameStarted:= true;
        ResumeGame;
      end;
    finally
      Free;
    end;
  finally
    FCadencer.Enabled:= true;
  end;
end;

procedure TGameEngine.OnAsyncTimer(Sender: TObject);
begin
  // ���������� ������������ �������
  if Assigned(FFPSText) and Assigned(FViewer) then begin
    FFPSText.Text:= Format('%0.f', [FViewer.FramesPerSecond]);
    FViewer.ResetPerformanceMonitor;
  end;
end;

procedure TGameEngine.OnCadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
begin
  // �������� ��������������� ��� ���������� ������� � �����
  FCadencer.Enabled:= false;
  try
    GetCursorPos(FCurPos);
    FCurPos.X:= FCurPos.X - MainForm.Left;
    FCurPos.Y:= FCurPos.Y - MainForm.Top;
    // ���������� ���������
    case FGameState of
      gsNone:    ;
      gsTiters:  ;
      gsOptions: ;
      gsIntro:   if Assigned(FGameIntro) then FGameIntro.DoProgressIntro(deltaTime);
      gsPause:   ;
      gsRun:     ;
    end;
    if Assigned(FGameMenuContainer) then
      FGameMenuContainer.DoGameMenuContainerProgress(deltaTime, FLastCurPos, FCurPos);
    if Assigned(fmOptions) then
      fmOptions.DoGUIElementProgress(deltaTime, FLastCurPos, FCurPos);
    if Assigned(FButtonClose) then
      FButtonClose.DoGUIElementProgress(deltaTime, FLastCurPos, FCurPos);
    if Assigned(FButtonMinimize) then
      FButtonMinimize.DoGUIElementProgress(deltaTime, FLastCurPos, FCurPos);
    if Assigned(FButtonMainMenu) then
      FButtonMainMenu.DoGUIElementProgress(deltaTime, FLastCurPos, FCurPos);

    FLastCurPos:= FCurPos;
  finally
    FCadencer.Enabled:= true;
  end;
end;

procedure TGameEngine.OnEndIntro(Sender: TObject);
begin
  // ���������� ��������� ��������
  FreeAndNil(FGameIntro);
  FGameState:= gsNone;

  // ������� ��������� ��� �������
  FGameMenuContainer:= TGameMenuContainer(Objects.AddNewChild(TGameMenuContainer));
  FGameMenuContainer.MenuItemFont.Font.Color:= $00F3CEA9;

  CreateMainMenu;
  CreateYesNoMenu;
  CreateOptionsMenu;
  CreateSystemMenuButtons;

  // ����� ��� �������� ���� � ����������
  fmOptions:= TfmOptions(Objects.AddNewChild(TfmOptions));
  fmOptions.Position.SetPoint(FGameMenuContainer.MenuList[2].AlignPosLine + 20 + fmOptions.Width / 2, FGameMenuContainer.MenuList[2].TopPosLine + fmOptions.Height / 2, 0);
  fmOptions.SetControls;

  FFPSText.MoveTo(FGUIElements);
  if Assigned(AVersionText) then
    AVersionText.MoveTo(FGUIElements);
  FGUIElements.MoveLast;

  //Application.CreateForm(tfmlog, fmlog);
  //fmlog.Show;
end;

procedure TGameEngine.OnFormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // ���������� ��� ������� �����
  CanClose:= FCanClose;
end;

procedure TGameEngine.OnFormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // ���������� ��� ������� �����

end;

procedure TGameEngine.OnFormKeyPress(Sender: TObject; var Key: Char);
begin
  // ���������� ��� ������� �����

end;

procedure TGameEngine.OnFormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // ���������� ��� ������� �����
  case Key of
    VK_ESCAPE: begin
      case FGameState of
        gsNone: begin
          if FGameMenuContainer.MenuList[1].Visible then
            FGameMenuContainer.ActivateMenu(0);
        end;
        gsTiters,
        gsOptions: FGameMenuContainer.ActivateMenu(0);
        gsIntro:  OnEndIntro(Sender);
        gsPause: begin
          if FIsGameStarted and FGameMenuContainer.MenuList[0].Visible then
            ResumeGame
          else
            PauseGame;
        end;
        gsRun: begin
          if FGameMenuContainer.MenuList[1].Visible then
            FGameMenuContainer.ActivateMenu(0)
          else
            if FIsGameStarted then PauseGame  else ResumeGame;
        end;
      end;
    end; // VK_ESCAPE: begin
    VK_F4: if (GameState <> gsIntro) and (ssAlt in Shift) then begin
      Key:=   0;
      Shift:= [];
      if not FGameMenuContainer.MenuList[1].Visible then begin
        FGameState:= gsPause;
        FGameMenuContainer.MenuList[1].Caption:= CAPTION_EXIT_GAME;
        FGameMenuContainer.ActivateMenu(1);
      end else
        ExitGame;
    end; // VK_F4: if ssCtrl in Shift then begin
    VK_RETURN: begin
      case GameState of
        gsNone:    ;
        gsIntro:   OnEndIntro(Sender);
        gsTiters:  FGameMenuContainer.ActivateMenu(0);
        gsOptions: ;
        gsPause:   ;
        gsRun:     ;
      end;
      if FGameMenuContainer.MenuList[1].Visible then
        FGameMenuContainer.MenuList[1].MenuItems[0].Click;
    end; //VK_RETURN: begin
  end; // case Key of
end;

procedure TGameEngine.OnGameMenuItemClick(AGameMenuItem: TGameMenuItem);
begin
  // ���������� "�����" �� ������ ����
  if Assigned(AGameMenuItem.OwnerMenu) then
    case AGameMenuItem.OwnerMenu.Index of
      // ������� ����
      0: case AGameMenuItem.Index of
           0: ResumeGame;
           1: StartNewGame;
           2: LoadGame;
           3: SaveGame;
           4: ShowOptions;
           5: ShowTiters;
           6: begin
             FGameMenuContainer.MenuList[1].Caption:= CAPTION_EXIT_GAME;
             FGameMenuContainer.ActivateMenu(1);
           end;
         end;
      // ���� "��" - "���"
      1: case AGameMenuItem.Index of
           0: begin
             if FGameMenuContainer.MenuList[1].Caption = CAPTION_EXIT_GAME then
               // ���� ������ "����� �� ���� ?"
               ExitGame
             else
             if FGameMenuContainer.MenuList[1].Caption = CAPTION_APPLY_OPTIONS then begin
               // ���� ������ "��������� ��������� ���� ?"
               ApplyOptions;
               FGameMenuContainer.ActivateMenu(0);
             end else
               //  ���� ������ "������ ����� ���� ?"
               if IsGameStarted then begin
                 FIsGameStarted:= false;
                 StartNewGame;
               end;
           end;
           1: FGameMenuContainer.ActivateMenu(0);
         end;
      // ���� "��������� ����"
      2: case AGameMenuItem.Index of
        0: begin
          // �������
          fmOptions.panelGraphics.Visible:= true;
          fmOptions.panelSound.Visible:=    false;
          fmOptions.panelControls.Visible:= false;
          fmOptions.panelGame.Visible:=     false;
        end;
        1: begin
          // ����
          fmOptions.panelGraphics.Visible:= false;
          fmOptions.panelSound.Visible:=    true;
          fmOptions.panelControls.Visible:= false;
          fmOptions.panelGame.Visible:=     false;
        end;
        2: begin
          // ����������
          fmOptions.panelGraphics.Visible:= false;
          fmOptions.panelSound.Visible:=    false;
          fmOptions.panelControls.Visible:= true;
          fmOptions.panelGame.Visible:=     false;
        end;
        3: begin
          // ����
          fmOptions.panelGraphics.Visible:= false;
          fmOptions.panelSound.Visible:=    false;
          fmOptions.panelControls.Visible:= false;
          fmOptions.panelGame.Visible:=     true;
        end;
          // �����
        4: FGameMenuContainer.ActivateMenu(0);
      end;
    end;
end;

procedure TGameEngine.OnGameMenuItemDblClick(AGameMenuItem: TGameMenuItem);
begin
  // ���������� "�������� �����" �� ������ ����

end;

procedure TGameEngine.OnGameMenuItemEnter(AGameMenuItem: TGameMenuItem);
begin
  // ���������� "�����" ������� � ������ ������ ����

end;

procedure TGameEngine.OnGameMenuItemLeave(AGameMenuItem: TGameMenuItem);
begin
  // ���������� "�����" ������� �� ������� ������ ����

end;

procedure TGameEngine.OnGameMenuShow(AGameMenu: TGameMenu);
begin
  // ���������� ������ ����
  FButtonMainMenu.Visible:= false;
  if AGameMenu.Index = 2 then
    fmOptions.Show
  else
    fmOptions.Hide;
end;

procedure TGameEngine.OnGUISystemButtonClick(AButton: TGUIButton);
begin
  // ���������� ������� ��������� ������
  if AButton.Name = BUTTON_NAME_CLOSE then begin
    if FGameState <> gsNone then
      FGameState:= gsPause;
    FGameMenuContainer.MenuList[0].MenuItems[6].Click;
  end else
  if AButton.Name = BUTTON_NAME_MINIMIZE then begin
    PauseGame;
    MainForm.WindowState:= wsMinimized;
  end else
  if AButton.Name = BUTTON_NAME_MAIN_MENU then begin
    PauseGame;
  end;
end;

procedure TGameEngine.OnGUISystemButtonEnter(AButton: TGUIButton);
begin
  // ���������� ����� ������� � ������ ��������� ������
  if AButton.Enabled then
    AButton.Material.FrontProperties.Diffuse.SetColor(1,1,1);
end;

procedure TGameEngine.OnGUISystemButtonLeave(AButton: TGUIButton);
begin
  // ���������� ������ ������� � ������� ��������� ������
  if AButton.Enabled then
    AButton.Material.FrontProperties.Diffuse.SetColor(0.8,0.8,0.8);
end;

procedure TGameEngine.OnViewerClick(Sender: TObject);
begin
  // ���������� ��� ���� �� ������
  GetCursorPos(FCurPos);
  FCurPos.X:= FCurPos.X - MainForm.Left;
  FCurPos.Y:= FCurPos.Y - MainForm.Top;
  case FGameState of
    gsNone:    ;
    gsTiters:  ;
    gsOptions: ;
    gsIntro:   if Assigned(FGameIntro) then OnEndIntro(self);
    gsPause:   ;
    gsRun:     ;
  end;
  if Assigned(FGameMenuContainer) then
    FGameMenuContainer.DoGameMenuContainerMouseClick(false, FCurPos);
  if Assigned(fmOptions) then
    fmOptions.DoGUIElementMouseClick(FCurPos);
  if Assigned(FButtonClose) then
    FButtonClose.DoGUIElementMouseClick(FCurPos);
  if Assigned(FButtonMinimize) then
    FButtonMinimize.DoGUIElementMouseClick(FCurPos);
  if Assigned(FButtonMainMenu) then
    FButtonMainMenu.DoGUIElementMouseClick(FCurPos);

  FLastCurPos:= FCurPos;
end;

procedure TGameEngine.OnViewerDblClick(Sender: TObject);
begin
  // ���������� ��� ���� �� ������
  GetCursorPos(FCurPos);
  FCurPos.X:= FCurPos.X - MainForm.Left;
  FCurPos.Y:= FCurPos.Y - MainForm.Top;
  case FGameState of
    gsNone:    ;
    gsTiters:  ;
    gsOptions: ;
    gsIntro:   if Assigned(FGameIntro) then OnEndIntro(self);
    gsPause:   ;
    gsRun:     ;
  end;
  if Assigned(FGameMenuContainer) then
    FGameMenuContainer.DoGameMenuContainerMouseClick(true, FCurPos);

  FLastCurPos:= FCurPos;
end;

procedure TGameEngine.OnViewerMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // ���������� ��� ���� �� ������

end;

procedure TGameEngine.OnViewerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  // ���������� ��� ���� �� ������

end;

procedure TGameEngine.OnViewerMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // ���������� ��� ���� �� ������

end;

procedure TGameEngine.OnViewerMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  // ���������� ��� ���� �� ������

end;

procedure TGameEngine.OnViewerMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  // ���������� ��� ���� �� ������

end;

procedure TGameEngine.OnViewerMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  // ���������� ��� ���� �� ������

end;

procedure TGameEngine.PauseGame;
begin
  // ��������� ���� �� �����
  FGameState:= gsPause;
  FGameMenuContainer.ActivateMenu(0);
end;

procedure TGameEngine.ResumeGame;
begin
  // ���������� ����, ������������ �� ����� ��� �����������
  if not FCadencer.Enabled then
    FCadencer.Enabled:= true;
  FIsGameStarted:= true;
  FGameMenuContainer.HideAllMenu;
  FGameState:= gsRun;
  FButtonMainMenu.Visible:= true;
end;

procedure TGameEngine.SaveGame;
begin
  // ��������� ����
  if IsGameStarted then begin
    FGameState:= gsPause;
    FCadencer.Enabled:= false;
    try
      with TSaveDialog.Create(self) do try
        Title:=      '�������� ���� ��� ����������';
        InitialDir:= FPaths.Saves;
        DefaultExt:= '.sav';
        Filter:=     '����� ���������� (*.sav)|*.sav';
        if Execute(MainForm.Handle) then begin

        end;
      finally
        Free;
      end;
    finally
      FCadencer.Enabled:= true;
    end;
  end;
end;

procedure TGameEngine.ShowIntro;
begin
  // �������� ��������
  if not Assigned(FGameIntro) then
    FGameIntro:= TGameIntro(Objects.AddNewChild(TGameIntro));
  FGameIntro.OnEndIntro:= OnEndIntro;
  FGameState:=            gsIntro;
  FIsGameStarted:=        false;
  FGameIntro.Visible:=    true;
end;

procedure TGameEngine.ShowOptions;
begin
  // �������� ��������� ����
  FGameState:= gsOptions;
  FGameMenuContainer.ActivateMenu(2);
end;

procedure TGameEngine.CreateSystemMenuButtons;
begin
  // ��������� ������ - ������ �����
  // ������ �������� ����
  FButtonClose:= TGUIButton(FGUIElements.AddNewChild(TGUIButton));
  with FButtonClose do begin
    Name:= BUTTON_NAME_CLOSE;
    LoadTexture(Paths.Textures + PIC_FILE_BTN_CLOSE);
    OnButtonClick:=      OnGUISystemButtonClick;
    OnButtonMouseEnter:= OnGUISystemButtonEnter;
    OnButtonMouseLeave:= OnGUISystemButtonLeave;
    Position.SetPoint(MainForm.Width -2 - Width / 2, Height / 2 + 2, 0);
    Material.FrontProperties.Diffuse.SetColor(0.8,0.8,0.8);
  end;
  // ������ ����������� ����
  FButtonMinimize:= TGUIButton(FGUIElements.AddNewChild(TGUIButton));
  with FButtonMinimize do begin
    Name:= BUTTON_NAME_MINIMIZE;
    LoadTexture(Paths.Textures + PIC_FILE_BTN_MINIMIZE);
    OnButtonClick:=      OnGUISystemButtonClick;
    OnButtonMouseEnter:= OnGUISystemButtonEnter;
    OnButtonMouseLeave:= OnGUISystemButtonLeave;
    Position.SetPoint(MainForm.Width - 4 - Width / 2 - FButtonClose.Width, Height / 2 + 2, 0);
    Material.FrontProperties.Diffuse.SetColor(0.8,0.8,0.8);
  end;
  // ������ ������ �������� ����
  FButtonMainMenu:= TGUIButton(FGUIElements.AddNewChild(TGUIButton));
  with FButtonMainMenu do begin
    Name:= BUTTON_NAME_MAIN_MENU;
    LoadTexture(Paths.Textures + PIC_FILE_BTN_MAIN_MENU);
    OnButtonClick:=      OnGUISystemButtonClick;
    OnButtonMouseEnter:= OnGUISystemButtonEnter;
    OnButtonMouseLeave:= OnGUISystemButtonLeave;
    Position.SetPoint(MainForm.Width - 6 - Width / 2 - FButtonClose.Width - FButtonMinimize.Width, Height / 2 + 2, 0);
    Material.FrontProperties.Diffuse.SetColor(0.8,0.8,0.8);
    Visible:= false;
  end;
end;

procedure TGameEngine.CreateOptionsMenu;
begin
  with FGameMenuContainer.AddGameMenu('OptionsMenu') do begin
    AlignPosLine:= 370;
    TopPosLine:=   150;
    Caption:= CAPTION_OPTIONS_GAME;
    HUDCaption.Position.SetPoint(20, TopPosLine - 40, 0);
    Align:= amiRight;
    MenuItemsInterval := 10;
    AddToSideLeft:= 20;
    AddToSideRight:= 10;
    //AddToSideTop:=      2;
    //AddToSideBottom:=   2;
    AccelerateAlpha:= 0.1;
    SpeedAlpha:= 0.5;
    AddMenuItem('OptionsMenu_Item1', '�������');
    AddMenuItem('OptionsMenu_Item2', '����');
    AddMenuItem('OptionsMenu_Item3', '����������');
    AddMenuItem('OptionsMenu_Item4', '����');
    AddMenuItem('OptionsMenu_Item5', '�����');
    AssignEventsToAllItems(OnGameMenuItemClick, OnGameMenuItemDblClick, OnGameMenuItemEnter, OnGameMenuItemLeave);
    OnShow:= OnGameMenuShow;
  end;
end;

procedure TGameEngine.CreateYesNoMenu;
begin
  with FGameMenuContainer.AddGameMenu('YesNoMenu') do begin
    TopPosLine := 150;
    Caption := CAPTION_EXIT_GAME;
    HUDCaption.Position.SetPoint(20, TopPosLine - 40, 0);
    Align := amiRight;
    MenuItemsInterval := 10;
    AddToSideLeft := 20;
    AddToSideRight := 10;
    //AddToSideTop:=      2;
    //AddToSideBottom:=   2;
    AccelerateAlpha := 0.1;
    SpeedAlpha := 0.5;
    AddMenuItem('YesNoMenu_Item1', '��');
    AddMenuItem('YesNoMenu_Item2', '���');
    AssignEventsToAllItems(OnGameMenuItemClick, OnGameMenuItemDblClick, OnGameMenuItemEnter, OnGameMenuItemLeave);
    OnShow := OnGameMenuShow;
  end;
end;

procedure TGameEngine.CreateMainMenu;
begin
  with FGameMenuContainer.AddGameMenu('MainMenu') do begin
    Caption := CAPTION_MAIN_MENU;
    HUDCaption.Position.SetPoint(30, TopPosLine - 40, 0);
    Align := amiRight;
    MenuItemsInterval := 10;
    AddToSideLeft := 20;
    AddToSideRight := 10;
    //AddToSideTop:=      2;
    //AddToSideBottom:=   2;
    AccelerateAlpha := 0.1;
    SpeedAlpha := 0.5;
    with AddMenuItem('MainMenu_Item1', '����������') do
      Visible := false;
    AddMenuItem('MainMenu_Item2', '����� ����');
    AddMenuItem('MainMenu_Item3', '���������');
    AddMenuItem('MainMenu_Item4', '���������');
    AddMenuItem('MainMenu_Item5', '���������');
    AddMenuItem('MainMenu_Item6', '�����');
    AddMenuItem('MainMenu_Item7', '�����');
    AssignEventsToAllItems(OnGameMenuItemClick, OnGameMenuItemDblClick, OnGameMenuItemEnter, OnGameMenuItemLeave);
    OnShow := OnGameMenuShow;
  end;
end;

procedure TGameEngine.ShowTiters;
begin
  // �������� �����
  FGameState:= gsTiters;
  FGameMenuContainer.HideAllMenu;
  FButtonMainMenu.Visible:= true;
end;

procedure TGameEngine.StartNewGame;
begin
  // ������ ����� ����
  if not IsGameStarted then begin
    FGameState:=     gsRun;
    FIsGameStarted:= true;
    FGameMenuContainer.HideAllMenu;
    FButtonMainMenu.Visible:= true;
  end else begin
    FGameMenuContainer.MenuList[1].Caption:= CAPTION_START_NEW_GAME;
    FGameMenuContainer.ActivateMenu(1);
  end;
end;

end.
