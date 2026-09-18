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
## @deftypefn {ciwarn} {@var{S} =} ciwarn (@var{A}, @var{B})
##
## Subtract two real scalars in compiled code.
##
## @code{@var{S} = ciwarn (@var{A}, @var{B})} returns @var{A} minus @var{B},
## computed by the package's oct-file.  The oct-file warns on purpose when it
## is built with warnings enabled, so the package is the fixture for the
## warnings job rather than a useful function.
##
## @end deftypefn
function S = ciwarn (A, B)
  if (nargin != 2)
    print_usage ();
  endif
  S = __ciwarn__ (A, B);
endfunction

%!assert_equal (ciwarn (5, 3), 2)
%!assert_equal (ciwarn (-1.5, 0.5), -2)
