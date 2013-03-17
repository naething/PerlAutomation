
var socket;

/* Set up a callback that is run When the webpage 
   has finished loading */
$(document).ready(function() {

    /* fetch a json array of objects from ther server */
    $.getJSON('Devices', function(data) {

        /* loop over all the returned objects */
        for (var i = 0; i < data.length; i++) {
            create_device(data[i]);
        }

       bind_callbacks();
       bind_websockets();
    });


});


function bind_websockets(){

    socket = io.connect();

    socket.on('message', function(m) {
        var msg = jQuery.parseJSON( m.text );
        console.log(msg);
        update_device(msg);
    });
}

/*

  <script src="/socket.io/socket.io.js"></script>
    <script>

        var socket = io.connect();
        var $wall  = $('#wall');

        var write = function(msg) {
            $wall.append('<li>' + msg + '</li>');
        };

        socket.on('message', function(m) {
            write( m.text );
        });

        socket.on('connect', function() {
            console.log('connected');
            socket.send('hello');
        });

        socket.on('error', function(e) {
            console.log('--- ERROR ---');
            console.log(e);
        });

        $('form').bind('submit', function(e) {
            e.preventDefault();

            socket.send($('#inp-txt').val());
            $('#inp-txt').val('');
        });

    </script>

    */

/****************************************************************************/
/* Add HTML elements for various devices */
/****************************************************************************/

function create_device(data){

    /* Find the device dev */
    var dev = $('#' + data.id);

    /* add a div for the title */
    dev.append('<div class="devname">' + data.name + '</div>');

    switch (data.type){
        case 'dimmableLight':
            dev.addClass('small_device');
            add_button(dev, 'SetTarget', 0, 'OFF');
            add_button(dev, 'SetTarget', 1, 'ON');
            dev.append('<div class="slider_box"><div class="slider" command="dim"></div></div>');
            update_dimmable_light(dev, data);
            break;
        case 'binarySwitch':
            dev.addClass('small_device');
            add_button(dev, 'SwitchPower1', 0, 'OFF');
            add_button(dev, 'SwitchPower1', 1, 'ON');
            update_binary_switch(dev, data);
            break;
        case 'securitySensor':
            dev.addClass('small_device');
            dev.append('<span class="sec_sensor"></span>');
            add_button(dev, 'SetArmed', 1, 'Arm');
            add_button(dev, 'SetArmed', 0, 'Bypass');
            update_security_sensor(dev, data);
            break;
        case 'custom':
            dev.append(data.html);
        default:
    }

}

function add_button(dev, cmd, payload, txt){
    dev.append('<span class="button" command="' + cmd + '" payload="' + payload + '">' + txt + '</span>');
}


/****************************************************************************/
/* Update HTML elements for various devices when changes occur */
/****************************************************************************/

function update_device(data) {

    /* Set the object name */
    var dev = $('#' + data.id);

    switch (data.type){
        case 'dimmableLight':
            update_dimmable_light(dev, data);
            break;
        case 'binarySwitch':
            update_binary_switch(dev, data);
            break;
        case 'securitySensor':
            update_security_sensor(dev, data);
            break;
        default:
    }

}

function set_on_off_button(dev, status){
    if (status == 0){
        dev.find('span[payload="0"]').addClass("down");
        dev.find('span[payload="1"]').removeClass("down");
    } else {
        dev.find('span[payload="1"]').addClass("down");
        dev.find('span[payload="0"]').removeClass("down");
    }
}

function update_binary_switch(dev, data){
    set_on_off_button(dev, data.status);
}

function update_dimmable_light(dev, data){
    console.log(data);
    dev.find('.slider').slider("value", data.level);
    set_on_off_button(dev, data.status);
}


function update_security_sensor(dev, data){
    set_on_off_button(dev, data.armed);
    if (data.tripped == 0){
        dev.find('.sec_sensor').addClass("clear");
        dev.find('.sec_sensor').removeClass("trip");
    } else {
        dev.find('.sec_sensor').addClass("trip");
        dev.find('.sec_sensor').removeClass("clear");
    }

}

