function [VectorAngle, VectorModule, Vector_xcol_yrow] = AngleBetweenTwoVectors(Vector1_xcol_yrow, Vector2_xcol_yrow)
% AUTHOR: Filippo Piccinini (E-mail: f.piccinini@unibo.it)
% DATE: 03 July 2013
% NAME: AngleBetweenTwoVectors
% 
% Given two input 2D vectors defined by their [x, y] = [col, row]
% coordinates, this function computes the angle, the module and the new [x,
% y] coordinates of the vector obtained performing the "vector product"
% operation (called also: cross product).
%
% PARAMETERS:
% 	Vector1_xcol_yrow    Input vector coordinates (in pixels) defined as: 
%                   [Vector1xcol, Vector1yrow];
% 	Vector2_xcol_yrow    Input vector coordinates (in pixels) defined as:
%                   [Vector2xcol, Vector2yrow];
%
% OUTPUT:
%   VectorAngle     Degrees of direction of the output vector.
%   VectorModule    Length (in pixels) of the output vector.
% 	Vector_xrow_ycol     Output vector coordinates (in pixels) defined as: 
%                   [VectorXcol, VectorYrow];
%
% EXAMPLE OF USAGE: 
% [VectorAngle, VectorModule, Vector_xrow_ycol] = AngleBetweenTwoVectors([2,0], [0,3]);

% Copyright © 2022 Filippo Piccinini and Attila Beleon.
% Contacts: filippo.piccinini85@gmail.com and beleonattila@gmail.com
% All rights reserved.
% 
% CometAnalyser and all related material is licensed
% under the: 3-clause BSD License.
%
% This software and all related material is provided by the copyright
% holders and contributors "as is" and any express or implied warranties,
% including, but not limited to, the implied warranties of merchantability
% and fitness for a particular purpose are disclaimed. In no event shall
% <copyright holder> be liable for any direct, indirect, incidental,
% special, exemplary, or consequential damages (including, but not limited
% to, procurement of substitute goods or services; loss of use, data, or
% profits; or business interruption) however caused and on any theory of
% liability, whether in contract, strict liability, or tort (including
% negligence or otherwise) arising in any way out of the use of this
% software, even if advised of the possibility of such damage.

Vector1x = Vector1_xcol_yrow(1);
Vector1y = Vector1_xcol_yrow(2);
Vector1abs = sqrt(Vector1_xcol_yrow.^2 + Vector1_xcol_yrow.^2);

Vector2x = Vector2_xcol_yrow(1);
Vector2y = Vector2_xcol_yrow(2);
Vector2abs = sqrt(Vector2_xcol_yrow.^2 + Vector2_xcol_yrow.^2);

VectorX = Vector1x + Vector2x;
VectorY = Vector1y + Vector2y;
Vector_xcol_yrow = [VectorX, VectorY];
VectorModule = sqrt(VectorX.^2 + VectorY.^2);

VectorAngleCos = acosd(VectorX/VectorModule);
if sign(VectorY)>=0
    VectorAngle = VectorAngleCos;
else
    VectorAngle = 360-VectorAngleCos;
end
