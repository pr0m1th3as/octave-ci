/*
Copyright (C) 2026 Andreas Bertsatos <abertsatos@biol.uoa.gr>

This file is part of octave-ci.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program; if not, see <http://www.gnu.org/licenses/>.
*/

#include <octave/oct.h>

DEFUN_DLD (__ciprobe__, args, ,
           "-*- texinfo -*-\n\
@deftypefn {Private Function} {@var{S} =} __ciprobe__ (@var{A}, @var{B})\n\
\n\
Return the sum of the real scalars @var{A} and @var{B}.\n\
\n\
@end deftypefn")
{
  if (args.length () != 2)
  {
    print_usage ();
  }
  double a = args(0).double_value ();
  double b = args(1).double_value ();
  return octave_value (a + b);
}
