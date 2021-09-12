#!/usr/bin/awk -f
BEGIN {
	dsz=0
	tr["\\"] = "B"
	tr[":"] = "C"
	tr["."] = "D"
	tr["="] = "E"
	tr["["] = "F"
	tr[">"] = "G"
	tr["]"] = "H"
	# 1 and 2 are fine in gas identifiers...
	tr["/"] = "K"
	tr["<"] = "L"
	tr["-"] = "M"
	tr["#"] = "N"
	# ...so is 0
	tr["+"] = "P"
	tr["?"] = "Q"
	tr["\""] = "R"
	tr["!"] = "S"
	tr["*"] = "T"
	tr["("] = "U"
	tr["|"] = "V"
	tr[","] = "W"
	tr[")"] = "Y"
	tr[";"] = "Z"

}
function safe(name) {
	if (name ~ /^[a-zA-Z_][a-zA-Z0-9]*$/)
		return name
	else {
		return "__sym_" dsz++
	}
}
function call(id) {
	printf("\t.int %s  # %s\n", dict[id], id)
}
function lit(v) {
	printf("\t.int lit,%s\n", v)
}
function tail(id) {
	printf("\t.int lit,body_%s, %s  # tail-call %s\n", dict[id], dict[">r"], id)
}
function def(name, type) {
	sym = safe(name)
	dict[name] = sym
	printf("\n%s %s  # %s\n", type, sym, name)
}
{
	if (copy) {
		if ($1==";") {
			copy=0
		} else
			print $0
		next
	}
	for (i=1; i<=NF; i++) {
		if (comment) {
			if ($i=="(")
				comment++
			else if ($i==")")
				comment--
			continue
		} else if (dict[$i]) {
			call($i)
		} else if ($i ~ /^pre/) {
			copy=1
			next
		} else {
			switch ($i) {
				case "code":
					i++
					def($i, "code")
					copy=1
					# fallthrough!
				case "\\":
					next
				case "(":
					comment=1
					break
				case "tail":
					i++
					tail($i)
					break
				case ":":
					i++
					def($i, "word")
					break
				case ";":
					call("unnest")
					break
				default:
					if ($i ~ /'.'/) {
						lit($i)
					} else if ($i ~ /^-?[0-9][0-9]*$/) {
						lit($i)
					} else {
						printf("Unrecognised word: %s\n", $i) >> "/dev/stderr"
						exit(1)
					}
			}
		}
	}
	
}
