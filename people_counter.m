

clear, clc, close all
delete(timerfindall)
count = 0;
imshown = 0;

cam = webcam();
cam.Resolution = '1280x720'
faceDetector = vision.CascadeObjectDetector('MaxSize',[150 150]);%'MinSize',[50 45]); % Finds faces by default
tracker = MultiObjectTrackerKLT;
initialNum=0
if ~isempty(initialNum)
    tracker.NextId  = initialNum(1) + 1;
end

frame = snapshot(cam);
frame = fliplr(frame);
frameSize = size(frame);


videoPlayer  = vision.VideoPlayer('Position',[200 100 fliplr(frameSize(1:2)+30)]);


tim = timer;
tim.ExecutionMode = 'FixedRate';
tim.Period = 20;
tim.TimerFcn = @(x,y) logThingSpeakData(tracker);
tim.StartDelay = 5;


fig = findall(groot,'Tag','spcui_scope_framework');
fig = fig(1); 
setappdata(fig,'RequestedClose',false)
fig.CloseRequestFcn = @(~,~) setappdata(fig,'RequestedClose',true);


bboxes = [];
while isempty(bboxes)
    framergb = snapshot(cam);
    frame = rgb2gray(framergb);
    bboxes = faceDetector.step(frame);
end
tracker.addDetections(frame, bboxes);


frameNumber = 0;
disp('Close the video player to exit');
start(tim)

while ~getappdata(fig,'RequestedClose')
    try
        framergb = snapshot(cam);
    catch
        framergb = snapshot(vidObj);
    end
    framergb = fliplr(framergb);
    frame = rgb2gray(framergb);
    
    if mod(frameNumber, 10) == 1

        bboxes = 2 * faceDetector.step(imresize(frame, 0.5));
        if ~isempty(bboxes)
            tracker.addDetections(frame, bboxes);
        end
    else
   
        tracker.track(frame);
    end
    
    if ~isempty(tracker.Bboxes)
  
        if any(mod(tracker.BoxIds,5) == 0) && imshown == 0
            count = count+1;
            displayFrame = insertObjectAnnotation(framergb, 'rectangle',...
                [tracker.Bboxes(1) tracker.Bboxes(2) 5 5] , ['Over crowded you are tha ' num2str(count*5) 'th visitor :)']);
            imwrite(displayFrame,'NewFace.png');
            imshow('NewFace.png');
            imshown = 1;
            pause(5)
            close(gcf)
            delete('NewFace.png');
        else
       
            if all(mod(tracker.BoxIds,5) ~= 0)
                imshown = 0;
            end
            displayFrame = insertObjectAnnotation(framergb, 'rectangle',...
                tracker.Bboxes, tracker.BoxIds);
            displayFrame = insertMarker(displayFrame, tracker.Points);
        end
        videoPlayer.step(displayFrame);
        tracker.BoxIds;
    else
        videoPlayer.step(framergb);
    end
    
    frameNumber = frameNumber + 1;
    
end


release(videoPlayer)
stop(tim)
clear vidObj
clear fig
clear videoPlayer