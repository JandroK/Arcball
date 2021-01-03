function varargout = trackBall(varargin)
% TRACKBALL MATLAB code for trackBall.fig
%      TRACKBALL, by itself, creates a new TRACKBALL or raises the existing
%      singleton*.
%
%      H = TRACKBALL returns the handle to a new TRACKBALL or the handle to
%      the existing singleton*.
%
%      TRACKBALL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRACKBALL.M with the given input arguments.
%
%      TRACKBALL('Property','Value',...) creates a new TRACKBALL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before trackBall_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to trackBall_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help trackBall

% Last Modified by GUIDE v2.5 03-Jan-2021 22:17:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @trackBall_OpeningFcn, ...
                   'gui_OutputFcn',  @trackBall_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before trackBall is made visible.
function trackBall_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to trackBall (see VARARGIN)


set(hObject,'WindowButtonDownFcn',{@my_MouseClickFcn,handles.axes1});
set(hObject,'WindowButtonUpFcn',{@my_MouseReleaseFcn,handles.axes1});
axes(handles.axes1);

handles.Cube=DrawCube();

handles.q0 = [1;0;0;0];
set(handles.axes1,'CameraPosition',...
    [0 0 5],'CameraTarget',...
    [0 0 -5],'CameraUpVector',...
    [0 1 0],'DataAspectRatio',...
    [1 1 1]);

set(handles.axes1,'xlim',[-3 3],'ylim',[-3 3],'visible','off','color','none');

% Choose default command line output for trackBall
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes trackBall wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = trackBall_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function my_MouseClickFcn(obj,event,hObject)

handles=guidata(obj);
xlim = get(handles.axes1,'xlim');
ylim = get(handles.axes1,'ylim');
mousepos=get(handles.axes1,'CurrentPoint');
xmouse = mousepos(1,1);
ymouse = mousepos(1,2);

if xmouse > xlim(1) && xmouse < xlim(2) && ymouse > ylim(1) && ymouse < ylim(2)
    handles.m0 = Map2DPointsTo3D(xmouse, ymouse);
    set(handles.figure1,'WindowButtonMotionFcn',{@my_MouseMoveFcn,hObject});
end
guidata(hObject,handles)

function my_MouseReleaseFcn(obj,event,hObject)
handles=guidata(hObject);
set(handles.figure1,'WindowButtonMotionFcn','');
guidata(hObject,handles);

function my_MouseMoveFcn(obj,event,hObject)

handles=guidata(obj);
xlim = get(handles.axes1,'xlim');
ylim = get(handles.axes1,'ylim');
mousepos=get(handles.axes1,'CurrentPoint');
xmouse = mousepos(1,1);
ymouse = mousepos(1,2);

if xmouse > xlim(1) && xmouse < xlim(2) && ymouse > ylim(1) && ymouse < ylim(2)
    
    % Calculate m1
    m1 = Map2DPointsTo3D(xmouse,ymouse);
    % Get past info
    m0 = handles.m0;
    q0 = handles.q0;
    % Calculate delta quaternoin
    dq = QuaternionFromTwoVectors(m0,m1);
    dq = dq/norm(dq);
    % Calculate actual quaternion
    qk = MultQuaternion(dq,q0);
    % Transform and publish differents attitudes
    UpdateAttitudes(qk, handles);
    % Redraw Cube
    handles.Cube = RedrawCube(qk,handles.Cube);
    % Save actual data
    handles.m0 = m1;
    handles.q0 = qk;
    
end
guidata(hObject,handles);

function h = DrawCube()

M = [-1 -1  1;  %Node 1
     -1  1  1;  %Node 2
      1  1  1;  %Node 3
      1 -1  1;  %Node 4
     -1 -1 -1;  %Node 5
     -1  1 -1;  %Node 6
      1  1 -1;  %Node 7
      1 -1 -1]; %Node 8

x = M(:,1);
y = M(:,2);
z = M(:,3);


con = [1 2 3 4;
       5 6 7 8;
       4 3 7 8;
       1 2 6 5;
       1 4 8 5;
       2 3 7 6]';

x = reshape(x(con(:)),[4,6]);
y = reshape(y(con(:)),[4,6]);
z = reshape(z(con(:)),[4,6]);

c = 1/255*[255 248 88;
    255 255 255;
    57 183 225;
    57 183 0;
    255 178 0;
    255 0 0];

h = fill3(x,y,z, 1:6);

for q = 1:length(c)
    h(q).FaceColor = c(q,:);
end

function h = RedrawCube(q,hin)

h = hin;
c = 1/255*[255 248 88;
    255 255 255;
    57 183 225;
    57 183 0;
    255 178 0;
    255 0 0];

M = [-1 -1  1;  %Node 1
     -1  1  1;  %Node 2
      1  1  1;  %Node 3
      1 -1  1;  %Node 4
     -1 -1 -1;  %Node 5
     -1  1 -1;  %Node 6
      1  1 -1;  %Node 7
      1 -1 -1]; %Node 8

%% TODO rotate M by using q
% Calculate rotation matrix
R = RotationMatrix(q);
% Rotate Cube
M=(R*M')';

x = M(:,1);
y = M(:,2);
z = M(:,3);


con = [1 2 3 4;
       5 6 7 8;
       4 3 7 8;
       1 2 6 5;
       1 4 8 5;
       2 3 7 6]';

x = reshape(x(con(:)),[4,6]);
y = reshape(y(con(:)),[4,6]);
z = reshape(z(con(:)),[4,6]);

for q = 1:6
    h(q).Vertices = [x(:,q) y(:,q) z(:,q)];
    h(q).FaceColor = c(q,:);
end


% --- Executes on button press in UpdateQuaternion.
function UpdateQuaternion_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateQuaternion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function euler_x_Callback(hObject, eventdata, handles)
% hObject    handle to euler_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of euler_x as text
%        str2double(get(hObject,'String')) returns contents of euler_x as a double


% --- Executes during object creation, after setting all properties.
function euler_x_CreateFcn(hObject, eventdata, handles)
% hObject    handle to euler_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function euler_y_Callback(hObject, eventdata, handles)
% hObject    handle to euler_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of euler_y as text
%        str2double(get(hObject,'String')) returns contents of euler_y as a double


% --- Executes during object creation, after setting all properties.
function euler_y_CreateFcn(hObject, eventdata, handles)
% hObject    handle to euler_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function euler_z_Callback(hObject, eventdata, handles)
% hObject    handle to euler_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of euler_z as text
%        str2double(get(hObject,'String')) returns contents of euler_z as a double


% --- Executes during object creation, after setting all properties.
function euler_z_CreateFcn(hObject, eventdata, handles)
% hObject    handle to euler_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function euler_angle_Callback(hObject, eventdata, handles)
% hObject    handle to euler_angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of euler_angle as text
%        str2double(get(hObject,'String')) returns contents of euler_angle as a double


% --- Executes during object creation, after setting all properties.
function euler_angle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to euler_angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function q0_0_Callback(hObject, eventdata, handles)
% hObject    handle to q0_0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of q0_0 as text
%        str2double(get(hObject,'String')) returns contents of q0_0 as a double


% --- Executes during object creation, after setting all properties.
function q0_0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to q0_0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function q1_Callback(hObject, eventdata, handles)
% hObject    handle to q1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of q1 as text
%        str2double(get(hObject,'String')) returns contents of q1 as a double


% --- Executes during object creation, after setting all properties.
function q1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to q1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function q2_Callback(hObject, eventdata, handles)
% hObject    handle to q2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of q2 as text
%        str2double(get(hObject,'String')) returns contents of q2 as a double


% --- Executes during object creation, after setting all properties.
function q2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to q2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function q3_Callback(hObject, eventdata, handles)
% hObject    handle to q3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of q3 as text
%        str2double(get(hObject,'String')) returns contents of q3 as a double


% --- Executes during object creation, after setting all properties.
function q3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to q3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in UpdateAngleAxis.
function UpdateAngleAxis_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateAngleAxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in UpdateEulerAngles.
function UpdateEulerAngles_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateEulerAngles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in UpdateRotationVector.
function UpdateRotationVector_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateRotationVector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function u1_Callback(hObject, eventdata, handles)
% hObject    handle to u1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of u1 as text
%        str2double(get(hObject,'String')) returns contents of u1 as a double


% --- Executes during object creation, after setting all properties.
function u1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to u1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function u2_Callback(hObject, eventdata, handles)
% hObject    handle to u2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of u2 as text
%        str2double(get(hObject,'String')) returns contents of u2 as a double


% --- Executes during object creation, after setting all properties.
function u2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to u2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function u3_Callback(hObject, eventdata, handles)
% hObject    handle to u3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of u3 as text
%        str2double(get(hObject,'String')) returns contents of u3 as a double


% --- Executes during object creation, after setting all properties.
function u3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to u3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function euler_roll_Callback(hObject, eventdata, handles)
% hObject    handle to euler_roll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of euler_roll as text
%        str2double(get(hObject,'String')) returns contents of euler_roll as a double


% --- Executes during object creation, after setting all properties.
function euler_roll_CreateFcn(hObject, eventdata, handles)
% hObject    handle to euler_roll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function euler_pitch_Callback(hObject, eventdata, handles)
% hObject    handle to euler_pitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of euler_pitch as text
%        str2double(get(hObject,'String')) returns contents of euler_pitch as a double


% --- Executes during object creation, after setting all properties.
function euler_pitch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to euler_pitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function euler_yaw_Callback(hObject, eventdata, handles)
% hObject    handle to euler_yaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of euler_yaw as text
%        str2double(get(hObject,'String')) returns contents of euler_yaw as a double


% --- Executes during object creation, after setting all properties.
function euler_yaw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to euler_yaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% Functions

function UpdateAttitudes(q, handles)
% Set Quaternion
set(handles.q0_0,'String', num2str(q(1)));
set(handles.q1,'String', num2str(q(2)));
set(handles.q2,'String', num2str(q(3)));
set(handles.q3,'String', num2str(q(4)));
% Set Euler principal Angles and axis
SetEulerPrincipalAngles();
% Set Euler Angles
SetEulerAngles();
% Set Rotation Vector
SetRotationVector();
% Set Rotation Matrix 
SetRotationMatrix();

function SetQuaternion(q)
%set(handles.q0_0,'String', num2str(q(1)));
set(handles.q1,'String', num2str(q(2)));
set(handles.q2,'String', num2str(q(3)));
set(handles.q3,'String', num2str(q(4)));

function SetEulerPrincipalAngles()

function SetEulerAngles()

function SetRotationVector()

function SetRotationMatrix()

% Convert a 2d point to 3d 
function m = Map2DPointsTo3D(x,y)
r = sqrt(3);

if x*x+y*y < 0.5*r*r
    z = abs(sqrt(r*r-(x*x)-(y*y))); 
else
    z = (r*r)/(2*sqrt(x*x+y*y));
    modulePoint = norm([x;y;z]); 
    x = r*x/modulePoint;
    y = r*y/modulePoint;
    z = r*z/modulePoint;
end
m=[x;y;z];

% Convert 2 vectors into a quaternion
function q = QuaternionFromTwoVectors(u,v)
m = sqrt(2 + 2 * dot(u, v));
w = (1 / m) * cross(u, v);
q =[0.5 * m; w(1); w(2); w(3)];

% Multiply two quaternions
function w = MultQuaternion(q,v)
q0=q(1);
v0=v(1);
qv=q(2:4);
vv=v(2:4);

w=zeros(4,1);
w(1)=q0*v0-(qv'*vv);
w(2:4)=q0*vv +v0*qv +cross(qv,vv);

function R = RotationMatrix(q)
qv=q(2:4);
qx = [0, -qv(3), qv(2); qv(3), 0, -qv(1); -qv(2), qv(1), 0];

a=(q(1)*q(1)-qv'*qv)*eye(3);
b=2*qv*qv';
c=2*q(1)*qx;

R= a+b+c;

% --- Executes on button press in ResetCube.
function ResetCube_Callback(hObject, eventdata, handles)
% hObject    handle to ResetCube (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.m0 = [0;0;0];
handles.q0 = [1;0;0;0];

UpdateAttitudes(handles.q0,handles);
handles.Cube = RedrawCube(handles.q0,handles.Cube);
guidata(hObject, handles);

function R = Eaa2rotMat(a,u)
% [R] = Eaa2rotMat(a,u)
% Computes the rotation matrix R given an angle and axis of rotation. 
% Inputs:
%	a: angle of rotation
%	u: axis of rotation 
% Outputs:
%	R: generated rotation matrix
n=norm(u);
Uu=(u/n);
I = eye(3);
Ux=[0,-Uu(3),Uu(2);Uu(3),0,-Uu(1);-Uu(2),Uu(1),0];
R=I*cosd(a)+(1-cosd(a))*(Uu*Uu')+Ux*sind(a);

function R = eAngles2rotM(yaw, pitch, roll)
% [R] = eAngles2rotM(yaw, pitch, roll)
% Computes the rotation matrix R given the Euler angles (yaw, pitch, roll). 
% Inputs:
%	yaw: angle of rotation around the z axis
%	pitch: angle of rotation around the y axis
%	roll: angle of rotation around the x axis
% Outputs:
%	R: rotation matrix
Ryaw=[cosd(yaw),sind(yaw),0;-sind(yaw),cosd(yaw),0;0,0,1];
Rpitch=[cosd(pitch),0,-sind(pitch);0,1,0;sind(pitch),0,cosd(pitch)];
Rroll=[1,0,0;0,cosd(roll),sind(roll);0,-sind(roll),cosd(roll)];
R=Ryaw'*Rpitch'*Rroll';


function [yaw, pitch, roll] = rotM2eAngles(R)
% [yaw, pitch, roll] = rotM2eAngles(R)
% Computes the Euler angles (yaw, pitch, roll) given an input rotation matrix R.
% Inputs:
%	R: rotation matrix
% Outputs:
%	yaw: angle of rotation around the z axis
%	pitch: angle of rotation around the y axis
%	roll: angle of rotation around the x axis
pitch=asind(-R(3,1));
if sind(pitch)==1
    roll=acosd(R(2,2));
    yaw=0;

elseif sind(pitch)==-1
    roll=acosd(R(2,2));
    yaw=0;

else
    roll=asind(R(3,2)/cosd(pitch));
    yaw=asind(R(2,1)/cosd(pitch));
end

function [a,u] = rotMat2Eaa(R)
% [a,u] = rotMat2Eaa(R)
% Computes the angle and principal axis of rotation given a rotation matrix R. 
% Inputs:
%	R: rotation matrix
% Outputs:
%	a: angle of rotation
%	u: axis of rotation 

a=acosd((trace(R)-1)/2);
if a==0
    u=rand(3,1);

elseif a==180
    M=(R+eye(3))/2;
    if (M(1,1))~= 0
        u(1)=sqrt(M(1,1));
        u(2)=M(1,2)/u(1);
        u(3)=M(1,3)/u(1);

    elseif (M(2,2))~= 0
        u(2)=sqrt(M(2,2));
        u(1)=M(2,1)/u(2);
        u(3)=M(2,3)/u(2);

    elseif (M(3,3))~= 0
        u(3)=sqrt(M(3,3));
        u(1)=M(3,1)/u(3);
        u(3)=M(3,2)/u(3);
    end
else
    Ux=(R-R')/(2*sind(a));
    u(1)=Ux(3,2);
    u(2)=Ux(1,3);
    u(3)=Ux(2,1);
end



function edit23_Callback(hObject, eventdata, handles)
% hObject    handle to q1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of q1 as text
%        str2double(get(hObject,'String')) returns contents of q1 as a double


% --- Executes during object creation, after setting all properties.
function edit23_CreateFcn(hObject, eventdata, handles)
% hObject    handle to q1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit24_Callback(hObject, eventdata, handles)
% hObject    handle to q2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of q2 as text
%        str2double(get(hObject,'String')) returns contents of q2 as a double


% --- Executes during object creation, after setting all properties.
function edit24_CreateFcn(hObject, eventdata, handles)
% hObject    handle to q2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit25_Callback(hObject, eventdata, handles)
% hObject    handle to q3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of q3 as text
%        str2double(get(hObject,'String')) returns contents of q3 as a double


% --- Executes during object creation, after setting all properties.
function edit25_CreateFcn(hObject, eventdata, handles)
% hObject    handle to q3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function roll_Callback(hObject, eventdata, handles)
% hObject    handle to roll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of roll as text
%        str2double(get(hObject,'String')) returns contents of roll as a double


% --- Executes during object creation, after setting all properties.
function roll_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function pitch_Callback(hObject, eventdata, handles)
% hObject    handle to pitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pitch as text
%        str2double(get(hObject,'String')) returns contents of pitch as a double


% --- Executes during object creation, after setting all properties.
function pitch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function yaw_Callback(hObject, eventdata, handles)
% hObject    handle to yaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yaw as text
%        str2double(get(hObject,'String')) returns contents of yaw as a double


% --- Executes during object creation, after setting all properties.
function yaw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end