# Team Codes from BOCA Dump

This is a simple script I wrote to extract team submitted codes from a BOCA
dump.

It requires you to have a BOCA dump, which can be created within "dump.sh"
script provided with BOCA.

If your dump contains more than one contest you may use the 'list' parameter
to list all available contests within the dump. This scripts extracts codes
from the contest that was marked as active when the dump was generated.

#Usage:
```
bash boca-teamcodes.sh bocadb.DATE.tar.gz [contest-number|list]
  DATE: is generate time of BOCA Dump
  ex: bocadb.08Nov2014-19h03min.tar.gz
  optional: contest-number of the contest witch data must be extracted
            list : lists all contests stored at bocadb
```

