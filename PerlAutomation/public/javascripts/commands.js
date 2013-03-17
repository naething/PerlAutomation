
/****************************************************************************/
/****************************************************************************/
/* This function needs to be called *after* all of the elements on the page are
   created (if )
*/
function bind_callbacks(){

/****************************************************************************/
/* button clicks */
	$(".button").click( function () {
		var cmd = new Object();
		cmd.id      = $(this).parents('.device').attr("id");
		cmd.command =$(this).attr("command");
		cmd.payload =$(this).attr("payload");
		$.ajax({
			contentType: 'application/json',
			type: "POST",
			url: "command",
			data: JSON.stringify({"command": cmd})
		});
	});

/****************************************************************************/
/* changes to a slider */ 
 	$( ".slider" ).slider({
 		change: function( event, ui ) { 
 			/* originalEvent exists if this change originated from the 
 			   user. Thie slider can also be changed via script, and 
 			   we only want to fire a command if this was a mouse / keyboard
 			   event from the user */
 			if(event.originalEvent){
	 			var cmd = new Object();
	 			cmd.id      = $(this).parents('.device').attr("id");
				cmd.command = $(this).attr("command");
				cmd.payload = ui.value.toString();
				$.ajax({
	 				contentType: 'application/json',
	 				type: "POST",
	 				url: "command",
	 				data: JSON.stringify({"command": cmd})
	 			});
			}
        }
	});

/****************************************************************************/
/* changes to a selection dropdown */
    $(".select").change(function(e) {
    	/* we are submitting a .ajax request so we don't want a post
           in addition to that... which we would get otherwise.
    	 */
    	e.preventDefault();

        var cmd = $(this).serialize();
        cmd = cmd.replace("=",".")
	    $.ajax({
	        contentType: 'application/json',
	        type: "POST",
	        url: "command",
	        data: JSON.stringify({ "command": cmd })
	    });

    });

}
