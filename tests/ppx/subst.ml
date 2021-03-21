let x = "low"

;;
if [%import "import.ml"].x.txt = "hel${x}orld".txt then exit 0 else exit 1
