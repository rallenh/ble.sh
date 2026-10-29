# source script for ble.sh interactive sessions -*- mode: sh; mode: sh-bash -*-

ble-import lib/core-complete
ble-import lib/core-test

ble/test/start-section 'ble/complete' 7

(
  ## @fn _collect
  ##   @arr[in] args ret
  ##   @var[out] ret
  function _collect {
    local text=${args[1]} p0=0 i out=
    for ((i=0;i<${#ret[@]};i++)); do
      ((p=ret[i]))
      if ((i%2==0)); then
        out=$out${text:p0:p-p0}'['
      else
        out=$out${text:p0:p-p0}']'
      fi
      p0=$p
    done
    ((p0<${#text})) && out=$out${text:p0}
    ret=$out
  }
  ble/test 'args=(akf Makefile 0); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='M[ak]e[f]ile'
  ble/test 'args=(akf Makefile 1); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='Makefile'
  ble/test 'args=(Mkf Makefile 1); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='[M]a[k]e[f]ile'
  ble/test 'args=(Maf Makefile 1); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='[Ma]ke[f]ile'
  ble/test 'args=(Mak Makefile 1); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='[Mak]efile'
  ble/test 'args=(ake Makefile 0); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='M[ake]file'
  ble/test 'args=(afe Makefile 0); ble/complete/candidates/filter:hsubseq/match "${args[@]}"; _collect' ret='M[a]ke[f]il[e]'
)

ble/test/end-section

ble/test/start-section 'ble/complete/action:progcomp' 4

(
  ## @fn _complete DATA CAND
  ##   Calls action:progcomp/complete for a candidate that completes the word
  ##   "host:/h/Doc", and returns the final insert string and suffix in ret.
  function _complete {
    local DATA=$1 CAND=$2 insert=$2 COMPS='host:/h/Doc' COMPV='host:/h/Doc'
    local comps_flags=v comps_fixed= COMP_PREFIX= insert_flags= suffix=
    ble/complete/action:progcomp/complete
    ret=$insert/$suffix/
  }

  # "ble/syntax-raw": inserted as is (scp generates remote files escaped for
  # the local and remote shells)
  ble/test '_complete :ble/syntax-raw:nospace: "host:/h/Docs\\\\\\ A/"' ret='host:/h/Docs\\\ A///'
  ble/test '_complete :ble/syntax-raw: "host:/h/Docs\\\\\\ A"' ret='host:/h/Docs\\\ A/ /'

  # without "ble/syntax-raw": requoted as before
  ble/test '_complete :nospace: "host:/h/Docs\\\\\\ A/"' ret="'host:/h/Docs\\ A/'//"
  ble/test '_complete : "host:/h/Docs\\ A\\ B"' ret="'host:/h/Docs A B'/ /"
)

ble/test/end-section
