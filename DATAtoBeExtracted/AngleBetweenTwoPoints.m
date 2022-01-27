function [Angle, Module] = AngleBetweenTwoPoints(Vector1_xcol_yrow, Vector2_xcol_yrow)
% AUTHOR: Filippo Piccinini (E-mail: f.piccinini@unibo.it)
% DATE: 11 September 2016
% NAME: AngleBetweenTwoPoints
% 
% Given two input points from the ULC = [1, 1], defined by 2D vectors
% defined by their [x, y] = [col, row] coordinates, this function computes
% the angle (in degree) and the module of the vector obtained performing
% the difference of the two input vectors. The angle is defined considering
% as angle = 0 a vector horizontal (i.e. aligned with the x-axis). The
% angle is computed keeping the origin in Vector1_xcol_yrow and the arrow
% directed to Vector2_xcol_yrow. The angles are computed in clockwise
% orientation (i.e. up = 270 deg, left = 180 deg, down = 90 deg, right = 0
% deg).
%
% PARAMETERS:
% 	Vector1_xcol_yrow    Input vector coordinates (in pixels) defined as: 
%                   [Vector1xcol, Vector1yrow];
% 	Vector2_xcol_yrow    Input vector coordinates (in pixels) defined as:
%                   [Vector2xcol, Vector2yrow];
%
% OUTPUT:
%   Angle           Degrees of direction of the output vector.
%   Module          Length (in pixels) of the output vector.
%
% EXAMPLE OF USAGE: 
% [VectorAngle, VectorModule] = AngleBetweenTwoPoints([2,0], [0,3]);
%
% TEST:
% O1 = [4, 7]; P2 = [4, 3]; P3 = [1, 7]; P4 = [4, 9]; P5 = [9, 7]; 
% P6 = [6, 5]; P7 = [1, 4]; P8 = [1, 10]; P9 = [6, 9];
% [Angle, Module] = AngleBetweenTwoPoints(O1, P5)

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

Vector1xcol = Vector1_xcol_yrow(1);
Vector1yrow = Vector1_xcol_yrow(2);
Vector1module = sqrt(Vector1_xcol_yrow.^2 + Vector1_xcol_yrow.^2);

Vector2xcol = Vector2_xcol_yrow(1);
Vector2yrow = Vector2_xcol_yrow(2);
Vector2module = sqrt(Vector2_xcol_yrow.^2 + Vector2_xcol_yrow.^2);

VectorXcolDif = Vector2xcol - Vector1xcol;
VectorYrowDif = Vector2yrow - Vector1yrow;
Module = sqrt(VectorXcolDif.^2 + VectorYrowDif.^2);

VectorAngleCos = acosd(VectorXcolDif/Module);
if sign(VectorYrowDif)>0
    Angle = 360-VectorAngleCos;
else
    Angle = VectorAngleCos;
end
