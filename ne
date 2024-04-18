#!/bin/sh
echo "Content-type: text/html"
echo ""

#interfaces
ifi='br-lan' #incoming
ifo='wlan0' #outgoing

pp="/cgi-bin/ne" #page path

QS_f="$(echo ${QUERY_STRING//&/;} | sed "s/%20//g")"
#printf "---$QS_f---" #for debug

if [ -n "$QS_f" ]; then
	#check on reset request
	if [ "$QUERY_STRING" = "reset" ]; then
		cmd_res="$(tc qdisc del dev $ifo root netem)"
		cmd_res+="$(tc qdisc del dev $ifi root netem)"
		#cmd_res+="$(/etc/init.d/network restart)"
		printf "<html><meta http-equiv='refresh' content='1; url=$pp' /><body><p>$cmd_res</p><p><a href='$pp'>Redirect...</a></p></body></html>"
		exit 0
	fi
	eval "$QS_f;"
	if [ "$ne_dir_if" = "1" ]; then
		if_int=$ifo
	else
		if_int=$ifi
	fi
	cmd_res="$(tc qdisc del dev $if_int root)"
	cmd_res+="$(tc qdisc add dev $if_int root netem delay "$ne_d"ms "$ne_d_j"ms loss "$ne_l"% "$ne_l_j"% corrupt "$ne_c"% "$ne_c_j"% duplicate "$ne_dup"% "$ne_dup_j"% reorder "$ne_r"% "$ne_r_j"% rate "$ne_rate"kbit)"
	if [ -n "$cmd_res" ]; then
		printf "Result: $cmd_res"
		exit 0
	fi
	printf "<html><meta http-equiv='refresh' content='0; url=$pp' /><body><p><a href='$pp'>Redirect</a></p></body></html>"
	exit 0
fi

cat << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<style type="text/css">
input:invalid {border: 2px dashed red;}
input:valid {border: 2px solid green;}
button {border: 2px solid red;}
table {border: 2px solid rgb(100, 120, 255);}
th {border: 1px solid grey;}
td {border: 1px solid grey;}
</style>
<head><meta charset="UTF-8"><title>Network Emulator</title></head>
<html><body>
<h1 id="h1_text">Network Emulator</h1>
<form name="gen_form" method="GET" action="">
<table>
<tr>
<th>delay</th>
<th><input type="number" name="ne_d" value="0" min="0" max="60000" step="1" />
<input type="number" name="ne_d_j" value="0" min="0" max="60000" step="1" /></th>
<td>select outgoing packet delay, ms; jitter, ms</td>
</tr>
<tr>
<th>loss</th>
<th><input type="number" name="ne_l" value="0" min="0" max="100" step="0.1" />
<input type="number" name="ne_l_j" value="0" min="0" max="100" step="0.1" /></th>
<td>independent loss probability to outgoing packets, %; jitter, %</td>
</tr>
<tr>
<th>corrupt</th>
<th><input type="number" name="ne_c" value="0" min="0" max="100" step="0.1" />
<input type="number" name="ne_c_j" value="0" min="0" max="100" step="0.1" /></th>
<td>random noise introducing an error in a random position  for a chosen percent of packets, %; jitter, %</td>
</tr>
<tr>
<th>duplicate</th>
<th><input type="number" name="ne_dup" value="0" min="0" max="100" step="0.1" />
<input type="number" name="ne_dup_j" value="0" min="0" max="100" step="0.1" /></th>
<td>percent of packets is duplicated before queuing them, %; jitter, %</td>
</tr>
<tr>
<th>reorder</th>
<th><input type="number" name="ne_r" value="0" min="0" max="100" step="0.1" />
<input type="number" name="ne_r_j" value="0" min="0" max="100" step="0.1" /></th>
<td>percent of packets is reordering (assuming 'delay 10ms' in the options list), %; jitter, %</td>
</tr>
<tr>
<th>rate</th>
<th><input type="number" name="ne_rate" value="500" min="10" max="102400" step="1" />
</th>
<td>delay packets based on packet size and is a replacement for TBF, kbit/sec.</td>
</tr>
<tr>
<th>direction (interface)</th>
<th><select name="ne_dir_if">
<option value="1">outgoing</option>
<option value="0" selected>incoming</option>
</select>
</th>
<td>packet direction</td>
</tr>
</table>
<p><input type="submit" value="Apply">
</p></form><a href="/cgi-bin/ne?reset"><button>Reset</button></a>
<script>
document.addEventListener("DOMContentLoaded", function () { // load page
// select all input
document.querySelectorAll('input').forEach(function (e) {
// if var exists in sessionStorage, then copy to input entry field
if (e.value === e.defaultValue) {e_value_in_storage = window.sessionStorage.getItem(e.name, e.value);
if (!(e_value_in_storage === null)) {e.value = e_value_in_storage;}}
// update var event
e.addEventListener('input', function () {
// write nev val var
window.sessionStorage.setItem(e.name, e.value);})})});
</script>
</body></html>
EOF