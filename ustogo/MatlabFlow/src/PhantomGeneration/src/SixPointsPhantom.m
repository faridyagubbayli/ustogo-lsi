%%  Copyright (C) 2014-2018  EPFL
%   ustogo: ultrasound processing Matlab pipeline
%  
%   Permission is hereby granted, free of charge, to any person
%   obtaining a copy of this software and associated documentation
%   files (the "Software"), to deal in the Software without
%   restriction, including without limitation the rights to use,
%   copy, modify, merge, publish, distribute, sublicense, and/or sell
%   copies of the Software, and to permit persons to whom the
%   Software is furnished to do so, subject to the following
%   conditions:
%  
%   The above copyright notice and this permission notice shall be
%   included in all copies or substantial portions of the Software.
%  
%   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%   OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
%   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
%   OTHER DEALINGS IN THE SOFTWARE.
%
%% Defines a phantom composed of six points in a flat space
%% (X: along the transducer surface, Z: depth).
%
% Inputs: none.
%
% Outputs: phantom_positions - Position of the scatterers in space (in
%                              meters)
%          phantom_amplitudes - Reflectivity of the scatterers
%          phantom_bbox - Coordinates of a bounding box around
%                         the scatterers' region, so that imaging
%                         can be done on that volume (in meters)

function [phantom_positions, phantom_amplitudes, phantom_bbox] = SixPointsPhantom()
       
   phantom_positions = [[-5, 5, -2, 2, -5, 5]', [0, 0, 0, 0, 0, 0]', [15, 15, 20, 20, 25, 25]'] / 1000;
   phantom_amplitudes = [1 1 1 1 0.5 0.5]';
   
   phantom_bbox.min_x = -10 / 1000;
   phantom_bbox.max_x = 10 / 1000;
   phantom_bbox.min_y = -5 / 1000;
   phantom_bbox.max_y = 5 / 1000;
   phantom_bbox.min_z = 10 / 1000;
   phantom_bbox.max_z = 30 / 1000;
   
end
