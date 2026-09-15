## Copyright (C) 2026 Andreas Bertsatos <abertsatos@biol.uoa.gr>
##
## This file is part of octave-ci.
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {ciprobe} {@var{S} =} ciprobe (@var{A}, @var{B})
##
## Add two real scalars in compiled code.
##
## @code{@var{S} = ciprobe (@var{A}, @var{B})} returns the sum of @var{A} and
## @var{B}, computed by the package's oct-file, so a passing test shows that
## the package compiled, installed and loaded.
##
## @end deftypefn
function S = ciprobe (A, B)
  if (nargin != 2)
    print_usage ();
  endif
  S = __ciprobe__ (A, B);
endfunction

%!assert_equal (ciprobe (2, 3), 5)
%!assert_equal (ciprobe (-1.5, 0.5), -1)
