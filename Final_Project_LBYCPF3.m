clc;
close all;
clearvars;
format long g;
format compact;
fontSize = 16;

fprintf('Beginning to run %s.m ...\n', mfilename);

% File names
videoFileName = 'test video.mp4'; % Replace with your video file name
videoPath = fullfile(pwd, videoFileName);

% Read video
videoReader = VideoReader(videoPath);

% Read the first frame to get dimensions
rgbTestImage = readFrame(videoReader);
emptyImage = imread('Parking Lot without Cars.jpg'); % Load reference image

maskImage = imread('Parking Lot Mask.png');

% Resize images to match each other
emptyImage = imresize(emptyImage, size(rgbTestImage(:, :, 1))); % Resize emptyImage without considering the 3rd dimension
maskImage = imresize(maskImage, size(rgbTestImage(:, :, 1))); % Resize maskImage without considering the 3rd dimension

% Display images
displayImage(rgbTestImage, 'Test Image', 1, fontSize);
displayImage(emptyImage, 'Reference Image', 2, fontSize);
displayImage(maskImage, 'Mask Image', 3, fontSize);

% Find cars in each frame
while hasFrame(videoReader)
    rgbTestImage = readFrame(videoReader);
    rgbTestImage = imresize(rgbTestImage, size(emptyImage)); % Resize each frame

    % Find cars
    [diffImage, mask, parkedCars] = findCars(emptyImage, rgbTestImage, maskImage);

    % Measure the percentage of white pixels within each rectangular mask
    [props, centroids, percentageFilled] = measurePixels(mask, parkedCars);

    % Visualize parking spaces
    visualizeSpaces(rgbTestImage, props, centroids, percentageFilled, fontSize);

    drawnow;
end

fprintf('Done running %s.m ...\n', mfilename);

% Functions
function displayImage(image, titleText, subplotNum, fontSize)
    subplot(1, 3, subplotNum);
    imshow(image, []);
    axis on image;
    title(titleText, 'FontSize', fontSize, 'Interpreter', 'None');
    drawnow;
end

function [diffImage, mask, parkedCars] = findCars(rgbEmptyImage, rgbTestImage, maskImage)
    diffImage = imabsdiff(rgbEmptyImage, rgbTestImage); % find difference between the Empty and Test
    diffImage = rgb2gray(diffImage); % Convert RGB Image to Greyscale
    mask = min(maskImage, [], 3) == 255; % Max saturation
    diffImage(~mask) = 0;

    kThreshold = 40;
    parkedCars = diffImage > kThreshold;
    parkedCars = imfill(parkedCars, 'holes');
    parkedCars = bwconvhull(parkedCars, 'objects');
end

function [props, centroids, percentageFilled] = measurePixels(mask, parkedCars)
    props = regionprops(mask, parkedCars, 'MeanIntensity', 'Centroid', 'Area');
    centroids = vertcat(props.Centroid);
    percentageFilled = [props.MeanIntensity];
end

function visualizeSpaces(rgbTestImage, props, centroids, percentageFilled, fontSize)
    figure;
    imshow(rgbTestImage);
    title('Marked Spaces. Green Spot = Available. Red X = Taken.', 'FontSize', fontSize);
    hold on;
    for k = 1:length(props)
        x = centroids(k, 1);
        y = centroids(k, 2);
        if props(k).Area > 100 && percentageFilled(k) > 0.40
            text(x, y + 20, 'X', 'Color', 'r', 'FontSize', 15, 'FontWeight', 'bold');
        else
            rectangle('Position', props(k).BoundingBox, 'EdgeColor', 'g', 'LineWidth', 1);
        end
    end
end
