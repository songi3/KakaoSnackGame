<%@ page pageEncoding="UTF-8"%>
<html>
<head>
<%@ include file="/WEB-INF/views/included/included_head.jsp"%>
<style>
html, body, .wrapper {
	overflow-x: hidden;
}

.wrapper {
	position : relative;
	display: flex;
	flex-flow: column nowrap;
	height: 100%;
	max-width : 500px;
	background-repeat: no-repeat;
	background-size: cover;
	background-image: url("resources/image/sample_back.png");
}

.wrapper .wrap-fg{
	display : none;
	z-index: 1;
	position : absolute;
	left : 0;
	right : 0;
	top :0;
	bottom : 0;
	background: rgba(0,0,0,0.6);
}

.wrapper .wrap-fg.on{
	display : block;
}

.wrapper .wrap-gameover{
	display : none;
	z-index: 3;
	position : absolute;
	left : 0;
	right : 0;
	top :0;
	bottom : 0;
	background: rgba(0,0,0,0);
	justify-content: center;
	align-items: center;
}

.wrapper .wrap-gameover.on{
	display: flex;
}

.gameover{
	width : 300px;
	height : 400px;
	background: #FFF;
	border-radius: 10px;
	box-shadow: 0px 10px 20px #222;
	display: flex;
	flex-flow : column nowrap;
	justify-content: center;
	align-items: center;
}

.gameover .icon{
	width : 150px;
	height : 150px;
	background-repeat: no-repeat;
	background-size: contain;
	background-position: center;
	margin-bottom: 10px;
}

.gameover .message{
	font-size: 2rem;
	font-weight: bold;
}

.head {
	width: 100%;
	height: 50px;
	display: flex;
	justify-content: space-between;
	
}

.bgm-source-board {
	width: 50px;
	height: 100%;
	background-repeat: no-repeat;
	background-size: contain;
	background-image: url("resources/image/sample_music_button.png");
}

.score-board {
	width: 100px;
	height: 50px;
	margin: auto;
	display: inline-block;
}

.score {
	font-size : 2rem;
	font-weight: bold;
	text-align: center;
}

.play-ground {
	flex: 1;
	position: relative;
}

.footer {
	width: 100%;
	height: 100px;
}

.candy {
	position: absolute;
	display: inline-block;
	z-index: 1;
	border-radius: 20px;
	background-repeat: no-repeat;
	background-size: contain;
	background-image: url("resources/image/sample_candy.png");
}

.candy.item {
	background-image: url("resources/image/sample_candy_item.png");
}

.candy.removed{
	background-image: url("resources/image/effect.gif");
}

</style>

<script>
	//FINAL
	const PER_SCORE				= 10; 	// 캔디 하나당 점수
	const CANDY_WIDTH			= 50;	// 캔디 넓이
	const CANDY_HEIGHT			= 50;	// 캔디 높이
	const TOUCH_PADDING			= 10;
	const ITEM_CREATE_PERCENT	= 0.2;  // 아이템 생성 확률

	//001 모두지우기
	//002 잠깐 멈추기
	const ITEMS = ["001", "002"]; 
	
	var startX;
	var startY;
	var endX;
	var endY;
	
	var candyMakeRate 		= 1000; 	// 사탕이 생성되는 간격 , 1000 = 1초
	var candyMakeRateSaved	= undefined;// 잠깐 멈추는 아이템을 위해 현재속도를 잠시 저장.
	var fallingSpeed 		= 100; 		// 사탕이 떨어지는 속도
	var totalScore			= 0; 		// 점수
	var makeCandyThread;
	var fallingSpeedUpThread;
	var fallingDistance = 10;
	
	//클릭시 소리
	var removeSound = new Audio();
	removeSound.src = getContextPath() + "/resources/audio/sample_remove_sound.wav";
	removeSound.preLoad = true;
	removeSound.controls = true;
	removeSound.autoPlay = false;

	function doTouchCandy(candy){
		var candy = $(candy);
		if(candy.hasClass("item")){ //캔디가 아이템을 가진 경우
	
			var itemID = candy.find(".item-id").val();
			switch(itemID){
			case ITEMS[0]: doItem001(); break;
			case ITEMS[1]: doItem002(); break;
			}
			
			function doItem001(){ // 모두 삭제
				removeAllCandy(true);
			}
			
			function doItem002(){ // 떨어지는속도, 캔디 생성 잠깐 멈추기
				fallingDistance 	= 0;
				candyMakeRateSaved 	= candyMakeRate; //생성속도 잠시 저장
				candyMakeRate 		= 99999999999; //무한
				
				setTimeout(function(){
					fallingDistance 	= 10;
					candyMakeRate		= candyMakeRateSaved; //생성속도 복구!
					candyMakeRateSaved 	= undefined;
				}, 2000);
			}
			
			function doItem003(){ // ??
					
			}
			
		} else{
			gainScore();			
		}
		
		removeCandy(candy);
	}
	
	//캔디 삭제 - 터치했을때, 다 떨어졌을때.
	function removeCandy(candy){
		//소리 효과
		removeSound.play();
		removeSound.currentTime = 0;

		candy.addClass('removed'); //이미지 변경
		setTimeout(function(){
			candy.remove();
		}, 300); 
		
		var intervalId = candy.find(".intervalID").val();
		clearInterval(intervalId); //쓰레드종료
	}
	
	//모든 캔디 삭제 
	function removeAllCandy(doEffect) {
		var candies = $(".candy");
		candies.each(function(){
			var tg = $(this);
			if(doEffect){
				tg.addClass('removed'); //이미지 변경
				setTimeout(function(){
					tg.remove();
				}, 300); 
			} else{
				tg.remove();
			}
			
			var intervalId = tg.find(".intervalID").val();
			clearInterval(intervalId); //쓰레드종료
		});
		
	}

	//사탕을 만들어 떨어트림
	function makeCandy(){
		var playGround = $(".play-ground");
		var candy = $("<div>", { "class" : "candy"});
		//candies.push(candy);
		candy.on("click", function(){
			doTouchCandy(this);
		});
		candy.appendTo(playGround);
		candy.css("width", CANDY_WIDTH);
		candy.css("height", CANDY_HEIGHT);
		
		if(Math.random() < ITEM_CREATE_PERCENT){ //아이템 캔디 생성
			candy.addClass("item");
		
			//어떤 아이템을 부여할지 랜덤으로~ 일단 코딩안함
			var item = Math.floor(Math.random() * ITEMS.length);
			candy.append($("<input>", {"class" : "item-id", type : "hidden", value : ITEMS[item]}));
		}
		
		//candy의 X(좌,우)좌표를 랜덤하게 지정한다. 
		var candyX 	= Math.random() * ((endX - CANDY_WIDTH) - startX) + startX;
		candy.offset({ "left": candyX });
		
		//사탕이 떨어지는 쓰레드
		var candyFalling = setInterval(function(){
			doFallCandy(candy);
		}, fallingSpeed);
		candy.append($("<input>", {"class" : "intervalID", type : "hidden", value : candyFalling})); //쓰레드ID
		
		function doFallCandy(tg){
			var tg = candy;
			var top = tg.offset().top;
			var toTop = top + fallingDistance;
			tg.offset({ "top": toTop });
			
			// 사탕이 다떨어지는 순간
			if(toTop - CANDY_HEIGHT >= endY){  
				gameover();
			}
		}
	}
	
	//게임 오버
	function gameover() {
		removeAllCandy(false)// 모든 캔디 삭제
		clearTimeout(makeCandyThread); // 사탕 생성 중지
		
		$(".wrap-fg").addClass("on");
		$(".wrap-gameover").addClass("on");
	}
	
	//점수 증가
	function gainScore(){
		 var score = $(".score");
		 totalScore = totalScore + PER_SCORE;
		 score.text(totalScore);
	}
	
	$(document).ready(function(){
		//초기화 (좌표)
		initXY();
		function initXY(){
			var playGround = $(".play-ground");
			startX 	= playGround.offset().left; 
			startY	= playGround.offset().top;
			endX	= startX + playGround.width();
			endY	= startY + playGround.height();
		}
		
		//사탕 생성 쓰레드
		loop();
		function loop() {
			makeCandy();
			makeCandyThread = setTimeout(loop, candyMakeRate);
		}

		//난이도UP 쓰레드 - 사탕이 빨리 떨어질수록, 캐디 만드는 속도는 빨라지도록
		fallingSpeedUpThread = setInterval(function(){
			fallingSpeed 	*= 0.95; 
			candyMakeRate 	*= 0.95;
		}, 1000);
		
	})
	
</script>
<body>
	<div class="wrapper">
		<div class="wrap-fg"></div>
		<div class="wrap-gameover">
			<div class="gameover">
				<div class="icon" style="background-image: url('${pageContext.request.contextPath}/resources/image/icon_play_gameover.gif');"></div>
				<div class="message">GAME OVER</div>
			</div>
		</div>
		
		<div class="head">
			<div class="bgm-source-board">
				<embed class="back-music-source" src="${pageContext.request.contextPath}/resources/audio/sample_bgm.mp3"
					autostart="true" hidden="true" loop="true" >
			</div>
			<div class="score-board">
				<div class="score">0</div>
			</div>
			<div></div>
		</div>
		<div class="play-ground"></div>
		<div class="footer"></div>
	</div>
</body>
</html>
