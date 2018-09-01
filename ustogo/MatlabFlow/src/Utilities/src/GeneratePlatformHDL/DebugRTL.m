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
%% Generates data structures that can be compared against the RTL simulation
%% directly.
%
% Inputs: probe - Description of the probe
%         image - A structure with fields describing the desired output
%                 output resolution
%         target_phantom - Phantom name
%         zone_count - If zone imaging is requested (zone_count > 1), how many zones the
%                      image should contain (zone_count in 2D, zone_count * zone_count in 3D)
%         compounding_count - If compound imaging is requested (compounding_count > 1), how
%                             many insonifications to compound
%         compounding_index - If compound imaging is requested (compounding_count > 1), for
%                             what insonification we are debugging
%         apod_full - the apodization-law matrix ("full" as we don't
%                     exploit symmetry to shrink it, yet)
%         rx_delay - The RX delay-law matrix
%         azimuth_index, elevation_index, radius_index - The polar coordinates
%                                                        of the voxel to debug
%         offset_min - Offset table generated by GeneratePlatformHDL
%         adc_precision - Precision of the system ADCs, in bits. See
%                         GeneratePlatformHDL
% 
% Outputs: ref_delay_2 - Reference RX delay table.
%          tx_delay_minus_tx_offset - TX delay table (given as two separate
%                                     signals tx_delay and tx_offset in the RTL)
%          c1_debug, c2_debug - Delay steering coefficients.
%          delay_int - Total delay table after steering.
%          adder_input - RF input samples as selected by delay_int, and as
%                        fed to the adder tree.
%
% Example usage:
% Start the TopLevel flow and stop at any time after initialization&insonification.
% Choose a voxel to debug:
% azimuth_index = 1;          % match it to theta_cnt_out + 1 (Matlab indices start from 1, while from 0 in RTL)
% elevation_index = 1;        % match it to phi_cnt_out + 1 (Matlab indices start from 1, while from 0 in RTL)
% radius_index = 1;           % match it to nt_cnt_out + 1 (Matlab indices start from 1, while from 0 in RTL)
% [ref_delay_2, tx_delay_minus_tx_offset, c1_debug, c2_debug, delay_int, adder_input] = DebugRTL(probe, image, zone_count, rf, apod_full, rx_delay, tx_delay, azimuth_index, elevation_index, radius_index, offset_min, adc_precision);
% 
% Notes:
% 1) The "adder_input" should be checked one or two cycles after "delay_int",
%    since the sample BRAMs have one or two cycles of latency (depending on the HIGH_PERFORMANCE setting).
% 2) Although this code does apply the same steering that Beamforming3D and the RTL do,
%    Matlab uses floating point, so the roundings may be different.
%    When comparing "delay_int" across this script and the RTL simulation,
%    it is normal to see that some values are 1 sample off.
%    However, the maximum difference should be 1 sample, and usually
%    ~80% of the delay values should match.
%    Similarly, since the RTL must use input samples truncated to
%    "adc_precision" while Matlab uses floating point, the input samples
%    are expected to be off by a corresponding amount. Apodization adds
%    further roundings.
% 3) TX delay = |VS| - |VO| + excitation_delay, where V = virtual source, O =
%    center of the transducer.
%    Matlab code: the whole "|VS| - |VO| + excitation_delay" is in the tx_delay
%    table.
%    RTL code: |VS| is called "tx_delay" while |VO| is called "tx_offset";
%    the excitation delay is added into the reference delay instead.
%    Therefore, to create something comparable, this script calculates
%    |VS| - |VO| ("tx_delay_minus_tx_offset") by subtracting the
%    excitation_delay from the tx_delay table.

function [ref_delay_2, tx_delay_minus_tx_offset, c1_debug, c2_debug, delay_int, adder_input] = DebugRTL(probe, image, target_phantom, zone_count, compounding_count, compounding_index, apod_full, rx_delay, azimuth_index, elevation_index, radius_index, offset_min, adc_precision)

% Attenuation coefficient [dB/cm]
atten_dB_cm = 1;

[~, ~, image_upper_limit_N, image_lower_limit_N, xz_sector, yz_sector] = GetPhantomCoordinates(probe, image);
focal_points_per_depth = (image_lower_limit_N - image_upper_limit_N) / image.radial_lines;

offset_at_depth = offset_min(1);

% TODO this code must be kept in sync with the InitializeBeamforming* code.
% Calculates the excitation delay of the probe and excitation.
excitation_impulse = conv(probe.impulse_response, conv(probe.impulse_response, probe.excitation));
excitation_envelope = abs(hilbert(excitation_impulse));
excitation_delay = find(excitation_envelope == max(excitation_envelope));

if (probe.is2D == 0)
    zone_index = floor((azimuth_index - 1) / (image.azimuth_lines / zone_count)) + 1;
    rx_delay_new = zeros(1, size(rx_delay, 1), size(rx_delay, 2));
    rx_delay_new(1, :, :) = rx_delay;
    rx_delay = rx_delay_new;
    apod_full_new = zeros(1, size(apod_full, 1), size(apod_full, 2));
    apod_full_new(1, :, :) = apod_full;
    apod_full = apod_full_new;
    xpitch = probe.pitch;
    ypitch = 0;
    xoff = probe.width / 2 - probe.transducer_width / 2;
    yoff = 0;
    elements_x = probe.N_elements;
    elements_y = 1;
else
    zone_index = zone_count * floor((elevation_index - 1) / (image.elevation_lines / zone_count)) + floor((azimuth_index - 1) / (image.azimuth_lines / zone_count)) + 1;
    xpitch = probe.pitch_x;
    ypitch = probe.pitch_y;
    xoff = probe.width / 2 - probe.transducer_width / 2;
    yoff = probe.height / 2 - probe.transducer_height / 2;
    elements_x = probe.N_elements_x;
    elements_y = probe.N_elements_y;
end

rx_delay_shrunk = zeros(size(rx_delay, 1), size(rx_delay, 2), image.radial_lines);
apod_full_shrunk = zeros(size(apod_full, 1), size(apod_full, 2), image.radial_lines);
for rind = 1 : image.radial_lines
    radius_index_scaled = (round(rind * focal_points_per_depth) + image_upper_limit_N - 1) * 1;
    rx_delay_shrunk(:, :, rind) = rx_delay(:, :, radius_index_scaled);
    apod_full_shrunk(:, :, rind) = apod_full(:, :, radius_index_scaled);
end
if (compounding_count > 1)
    insonification_index = compounding_index;
else
    insonification_index = zone_index;
end
sampling_indices = (round((1 : image.radial_lines) * focal_points_per_depth) + image_upper_limit_N - 1);
tx_delay_shrunk = LoadShrunkTXDelayFromDisk(target_phantom, insonification_index, sampling_indices);
% For uniformity with the 3D case
if (probe.is2D == 0)
    tx_delay_shrunk = reshape(tx_delay_shrunk, 1, size(tx_delay_shrunk, 1), size(tx_delay_shrunk, 2));
end
% rf_im - Radio-frequency matrix containing the raw data of the
% backscattered echoes (M*N*O, where M*N is the number of probe elements,
% O is the number of time samples)
[max_radius, rows, columns, ~, ~] = LoadRFDataMatrixMetadataFromDisk(target_phantom);
rf_im = LoadRFDataMatrixFromDisk(target_phantom, insonification_index, max_radius, rows, columns);

% Normalize the RF values so that the maximum-amplitude echoes
% almost saturate the ADCs
maxval = max(max(max(abs(rf_im))));
maxrange = 2 ^ (adc_precision - 1);
amplif_factor = maxrange / maxval;

% Apply TGC
% No need to apply compensation for the expanding aperture like Beamform2D/3D,
% since the HW uses a full aperture at all depths
tgc = 10 .^ (atten_dB_cm / 20 * probe.c * (1 : size(rf_im, 3)) / probe.fs * 1e2) / 2;
tgc_elements = ones(elements_x * elements_y, 1) * tgc;
tgc_elements_matrix = reshape(tgc_elements, elements_y, elements_x, size(rf_im, 3));
rf_im = tgc_elements_matrix .* rf_im;

d_phi = yz_sector / image.elevation_lines;
phi_start = - yz_sector / 2 + d_phi / 2;
phi = phi_start + (elevation_index - 1) * d_phi;
d_theta = xz_sector / image.azimuth_lines;
theta_start = - xz_sector / 2 + d_theta / 2;
theta = theta_start + (azimuth_index - 1) * d_theta;

for	row_index = 1 : elements_y
    for column_index = 1 : elements_x
        added_delay_elev_n = ((row_index - 1) * ypitch + yoff) * sin(phi) * cos(theta) * probe.fs / probe.c;
        added_delay_azimuth_n = ((column_index - 1) * xpitch + xoff) * sin(theta) * probe.fs / probe.c;

        computed_tx_delay(row_index, column_index) = tx_delay_shrunk(elevation_index, azimuth_index, radius_index);
        computed_rx_delay(row_index, column_index) = rx_delay_shrunk(row_index, column_index, radius_index) - added_delay_elev_n - added_delay_azimuth_n;
        % -1 to produce values comparable to the RTL's
        % ref_delay_2(row_index, column_index) = tx_delay_shrunk(elevation_index, azimuth_index, radius_index, 1) + rx_delay_shrunk(row_index, column_index, radius_index) - 1 - offset_at_depth;
        ref_delay_2(row_index, column_index) = rx_delay_shrunk(row_index, column_index, radius_index) + excitation_delay - 1 - offset_at_depth;
        % TODO this signal could be shaped to match better the RTL maybe.
        % Either try to change this or the RTL.
        tx_delay_minus_tx_offset(row_index, column_index) = tx_delay_shrunk(elevation_index, azimuth_index, radius_index) - excitation_delay;
        c2_debug(row_index, column_index) = - added_delay_elev_n;
        c1_debug(row_index, column_index) = - added_delay_azimuth_n;
        totd(row_index, column_index) = ref_delay_2(row_index, column_index) + tx_delay_minus_tx_offset(row_index, column_index) + c1_debug(row_index, column_index) + c2_debug(row_index, column_index);
        delay_int(row_index, column_index) = floor(totd(row_index, column_index) + 0.5); % The RTL adds 0.5 then truncates

        % The actual delay used by Matlab does not have the -1 and does not need subtracting any offset
        matlab_delay(row_index, column_index) = delay_int(row_index, column_index) + 1 + offset_at_depth;
        used_rf(row_index, column_index) = rf_im(row_index, column_index, matlab_delay(row_index, column_index), 1);
        used_rf_scaled(row_index, column_index) = used_rf(row_index, column_index) * amplif_factor;
        adder_input(row_index, column_index) = used_rf_scaled(row_index, column_index) * apod_full_shrunk(row_index, column_index, size(apod_full_shrunk, 3));
    end
end

disp(['This focal point is in zone ' num2str(zone_index)]);

% This data is in 16.2 format
adder_input = round(adder_input * 4) / 4;

openvar('ref_delay_2');
openvar('tx_delay_minus_tx_offset');
openvar('c1_debug');
openvar('c2_debug');
openvar('delay_int');
openvar('adder_input');

% These are not passed out, so to display them, a breakpoint on the last
% line of this function must be set.
%openvar('matlab_delay');
%openvar('used_rf');
%openvar('used_rf_scaled');
