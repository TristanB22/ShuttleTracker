<?php
$newCoordsArray = explode(",",$_POST['loc']);
// $newCoords = [
	// $_POST['time'] => [
		// floatval($newCoordsArray[0]),
		// floatval($newCoordsArray[1])
	// ]
// ];

$url = 'route.json';

$pastCoords = json_decode(file_get_contents($url), TRUE);

// array_push($pastCoords[0], $newCoords);
$pastCoords[$_POST['time']] = [
		floatval($newCoordsArray[0]),
		floatval($newCoordsArray[1])
];
	
$json = json_encode($pastCoords, JSON_PRETTY_PRINT);

$file = fopen($url,'w');
fwrite($file, $json);
fclose($file);
		  
echo 'Added Location' ;
?>
