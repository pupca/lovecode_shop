function remove_img_classes() {
	$("#img1").removeClass("active");
	$("#img2").removeClass("active");
	$("#img3").removeClass("active");
	$("#img4").removeClass("active");
	$("#img5").removeClass("active");
}

var myPlayer = videojs('#hero_video');

myPlayer.on('timeupdate', function(e) {
    // if (myPlayer.currentTime() >= pausetime) {
    //     myPlayer.pause();
    // }

    if (myPlayer.currentTime() >= 0.0 && myPlayer.currentTime() <=  6.0) {
    	remove_img_classes()
    	$("#img1").addClass("active");
    } else if (myPlayer.currentTime() >= 6.0 && myPlayer.currentTime() <=  12.0) {
    	remove_img_classes()
    	$("#img2").addClass("active");
    } else if (myPlayer.currentTime() >= 12.0 && myPlayer.currentTime() <=  18.0) {
    	remove_img_classes()
    	$("#img3").addClass("active");
    } else if (myPlayer.currentTime() >= 18.0 && myPlayer.currentTime() <=  24.0) {
    	remove_img_classes()
    	$("#img4").addClass("active");
    } else {
    	remove_img_classes()
    	$("#img5").addClass("active");
    }




    $('.progress-bar').stop().animate({
            width: (myPlayer.currentTime() * 100 / 31) + "%"
        }, 100);


    // console.log(myPlayer.currentTime())
});

myPlayer.play();

$("#link_img1").click(function(e) {
		e.preventDefault();
		myPlayer.currentTime(0)
});

$("#link_img2").click(function(e) {
		e.preventDefault();
		myPlayer.currentTime(6)
});

$("#link_img3").click(function(e) {
		e.preventDefault();
		myPlayer.currentTime(12)
});

$("#link_img4").click(function(e) {
		e.preventDefault();
		myPlayer.currentTime(18)
});

$("#link_img5").click(function(e) {
		e.preventDefault();
		myPlayer.currentTime(24)
});






if (window.location.search.indexOf('slack=error') > -1) {
	$("#waitlist-workemail-info").html("Opps! Slack has made a boo-boo. Please sign up with your regular email adress").attr("style", "color:red;").show()
}

if (window.location.search.indexOf('ref=producthunt') > -1) {
	$(".producthunt").show();
}

$("#slack_url").attr("href", $("#slack_url").attr("href") + "&redirect_uri=" + window.location.protocol + "//" + window.location.host + "/slack")

if (window.location.search.indexOf('slack=ok') > -1) {
	$("#waitlist").hide()
	$("#waitlist_success").show()
}

function isValidEmailAddress(emailAddress) {
	var pattern = /^([a-z\d!#$%&'*+\-\/=?^_`{|}~\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]+(\.[a-z\d!#$%&'*+\-\/=?^_`{|}~\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]+)*|"((([ \t]*\r\n)?[ \t]+)?([\x01-\x08\x0b\x0c\x0e-\x1f\x7f\x21\x23-\x5b\x5d-\x7e\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]|\\[\x01-\x09\x0b\x0c\x0d-\x7f\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))*(([ \t]*\r\n)?[ \t]+)?")@(([a-z\d\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]|[a-z\d\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF][a-z\d\-._~\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]*[a-z\d\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])\.)+([a-z\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]|[a-z\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF][a-z\d\-._~\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]*[a-z\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])\.?$/i;
	return pattern.test(emailAddress);
};

$('#waitlist-button').click(function(e){

	console.log(isValidEmailAddress($('#waitlist-email').val()))
	if (isValidEmailAddress($('#waitlist-email').val())) {
		$("#waitlist").removeClass("fail")
		$("#waitlist").removeClass("success")


		$.post( "/signup", {"email": $('#waitlist-email').val()}, function() {
			$("#waitlist").hide()
			$("#waitlist_success").show()
		})
		.fail(function(e) {
			if (e.status == 412) {
				$("#waitlist-workemail-info").show()
				$("#waitlist").addClass("fail")
			} else {
				$("#waitlist").addClass("fail")
			}
		});
	} else {
		$("#waitlist").addClass("fail")
	}

	$("#waitlist-email").on("keyup paste", function(){
		$("#waitlist").removeClass("fail")
	})
});

$('a[href*="#"]:not([href="#"])').click(function() {
	if (location.pathname.replace(/^\//,'') == this.pathname.replace(/^\//,'') && location.hostname == this.hostname) {
		var target = $(this.hash);
		target = target.length ? target : $('[name=' + this.hash.slice(1) +']');
		if (target.length) {
			$('html, body').animate({
				scrollTop: target.offset().top
			}, 400);
			return false;
		}
	}
});

$('#getupdates').click(function(e){
	e.preventDefault();
	var target = $(this);
	$('html, body').animate({scrollTop: 0 }, 400, function(){
		$('#waitlist-email').focus();
	});
});
