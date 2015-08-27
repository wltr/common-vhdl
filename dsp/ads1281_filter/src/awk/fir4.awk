#
# Generate FIR filter coefficients
# Copyright (c) Quentin King <quentin.king@cern.ch>
#

BEGIN {
  usage = "gawk -f fir4.awk z0 z1 z2 z3"

  N = 4

  if(ARGC != N+1)
  {
    print "Invalid number of arguments:", ARGC > "/dev/stderr"
    print usage > "/dev/stderr"
    exit -1
  }

  # Calculate root array from zeros

  L = 0

  for(i=0 ; i < N ; i++)
  {
    z[i] = ARGV[i+1]
    L    = L + z[i]
  }

  p[0] = 0

  for(i=1 ; i < N ; i++)
  {
    p[i] = z[0] + z[i]
  }

  for(i=0 ; i < N ; i++)
  {
    root[z[i]]     = root[z[i]]     - 1
    root[L - z[i]] = root[L - z[i]] - 1
    root[p[i]]     = root[p[i]]     + 1
    root[L - p[i]] = root[L - p[i]] + 1
  }

  filter_len = L - N + 1

  # Loops to calculate FIR coefficients

  print "TIME,ACC4,ACC3,ACC2,ACC1,ROOT"

  acc1 = 0
  acc2 = 0
  acc3 = 0
  acc4 = 0

  for(flt_idx = 0 ; flt_idx <= L ; flt_idx++)
  {
    acc1 = acc1 + root[flt_idx]
    acc2 = acc2 + acc1
    acc3 = acc3 + acc2
    acc4 = acc4 + acc3

    print flt_idx "," acc4 "," acc3 "," acc2 "," acc1 "," 0 + root[flt_idx]
  }

  exit 0
}
