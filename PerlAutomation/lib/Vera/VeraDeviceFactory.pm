
use Switch;

#-----------------------------------------------------------------------------
# Probably a cleaner way of doing this, but... I don't know how!
sub VeraDeviceFactory{
    my $type = shift;
    my $json_device_ref = shift;

    switch ($type){
        case 'Virtual'             { return VeraDevice->new($json_device_ref); }
        case 'Sensor'              { return VeraSensor->new($json_device_ref); }
        case 'Humidity Sensor'     { return VeraDevice->new($json_device_ref); }
        case 'Dimmable Light'      { return VeraDimmableLight->new($json_device_ref); }
        case 'Switch'              { return VeraSwitch->new($json_device_ref); }
        case 'Camera'              { return VeraDevice->new($json_device_ref); }
        case 'Alarm Panel'         { return VeraDevice->new($json_device_ref); }
        case 'Temperature Sensor'  { return VeraDevice->new($json_device_ref); }
        case 'Alarm Partition'     { return VeraDevice->new($json_device_ref); }
        case 'Door lock'           { return VeraDevice->new($json_device_ref); }
        case 'Thermostat'          { return VeraDevice->new($json_device_ref); }
        else {
            warn("Unknown Device Types ${type}\n");
            return VeraDevice->new($json_device_ref);
        }
    }
};

1;