// ****************************************************************
//                           PARAMETERS:
// ---------------------------------------------------------------

window.app_settings = {
	server: {
		base_address: 'https://ROOT_DOMAIN',
		ws_base_address: 'wss://ROOT_DOMAIN',
	},
	downloadAllToLocalStorage: false, // this refers to the case where the data need to be downloaded again to the local storage (e.g., after reinstalling the app because of a problem)
	minDailyDataPointsToStoreLocally: 20,
	experimentalDayStartingHour: 5, // Possiblie assignments are 0-23. Assign 0 to simply seperate between days.  Relevant for example to determine the time at day to empty container according to a 24h watch. 
	pressesRequired: 2,
	forceDeval: null, // for debugging purposes
	// optional stuff for counterbalance:
	// * [Currently it works such that the day in the middle will be assigned with devaluation and the othe with control manipulations]
	optionalDaysForFirstDeval: [2, 3, 4], // The day not chosen for devaluation will be used as a comparable valued day
	dayToFinishExperiment_ShortTraining: 5,
	optionalDaysForLastDeval: [9, 10, 11], // The day not chosen for devaluation will be used as a comparable valued day
	dayToFinishExperiment_LongTraining: 12,
	// Determine when to induce maniplations:
	toPersonalizedManpulationTime: false,
	// for non-personalized time of manipulation:
	entry_to_manipulate_in: 5, // manipulation will occur on the entry_to_manipulate_in, namely entry_to_manipulate_in - 1 will have to be completed
	hour_at_day_to_manipulate_anyway: 14,
	// for personalized time of manipulation:
	daysToBaseUponFirstDeval: [1], // days to base upon first devluation/control manipulation time
	daysToBaseUponLastDeval: [8], //[6, 7], // days to base upon last devluation/control manipulation time
	referenceDayPrecentileForManipulation: 0.5, // if referenceDayPrecentile=0.5 it will take the median, 0.25 quarter of the presses in a day etc.
	nTimesToShowCaveIfNotEntering: 2,
	maxSecsToShowCaveAgainIfNotEntering: 30,
	nTrialsBeforeNotifyGameOver: 3,
	nDailyEntriesRequired: function () { return this.entry_to_manipulate_in; },
	manipulationImageID: function (manipulationType) {
		if (manipulationType == 'devaluation') {
			return 'warehouse_full';
		} else if (manipulationType == 'still_valued' || manipulationType == 'still_valued_post_deval' || manipulationType == 'still_valued_replacing_devaluation') { // i.e., 'still_valued'
			return 'warehouse_half';
		}
	},
	msToRecordTimeSinceManipulationActivation: 500, // in ms
	hideOutcome: {
		hide: true,
		toPersonalizedOutcomeHidingTime: false, // normally the value should be similar to toPersonalizedManpulationTime
		// option 1:
		hideOnlyUnderManipulationPeriods: false, // if false will hide every day from what we set in daysToHideAt
		// for options 2 and 3:
		daysToHideAt: { // detemine according to group name
			short_training: [2, 3, 4],
			long_training: [9, 10, 11],
			long_training_parallel_manipulations: [2, 3, 4, 9, 10, 11],
		}, // [2, 3, 4, 5, 8, 10, 12],
		// option 2: relevant if hideOnlyUnderManipulationPeriods is false and toPersonalizedOutcomeHidingTime is true;
		daysToBaseUponHidingTime: { // detemine according to group name
			short_training: [[1], [1], [1]],
			long_training: [[8], [8], [8]],
			long_training_parallel_manipulations: [[1], [1], [1], [8], [8], [8]], // [[1], [1, 2], [2, 3], [3], [5, 6, 7], [9], [10, 11]], // This should specify an array for each value in daysToHideAt
		}, // [2, 3, 4, 5, 8, 10, 12],
		relativeTimeOfDayToStart: 0.25, // if referenceDayPrecentile=0.5 it will take the median, 0.25 quarter of the presses in a day etc.
		// option 3: relevant if hideOnlyUnderManipulationPeriods is false and toPersonalizedOutcomeHidingTime is false
		entry_to_hideOutcome_in: 3,
		hour_at_day_to_hideOutcome_anyway: 12,
	},
	rewards: {
		isRatioSchedule: true,
		winningRate: 3, //per entries if isRatioSchedule is true; per seconds if isRatioSchedule is false, 
		winningChancePerUnit: function () {
			return 1 / this.winningRate;
		},

		isVariableReward: false,
		// for VariableReward (will be computed unifomly in the given range):
		minWinningSum: 20,
		maxWinningSum: 30,
		// for constant reward:
		rewardConstantSum: 15,

		// Sure win stuff:
		winAnywayIfMultipleNonWins: true, // this is to make sure that in case a participant did not win many times they will.
		RelativeNonWinUnitsBeforeSureWinning: function () {
			return this.winningRate * 2; // this means that if for example this is a variable ratio of 10, after 20 no wins the 21 attempt will be a sure win.
		},

		// First daily entries stuff:
		enforceFirstEntryWinSecondEntryNoWin: true,

		notifyRewardContainerReset: true,
	},
	cost: {
		isCost: true,
		isCostPerPress: false,
		isVariableCost: false,
		minCostSum: 1,
		maxCostSum: 5,
		// for constant cost:
		costConstantSum: 1,
		presentCost: true, // O'Doherty did not use visual feedback for the cost, Gillan did (in their MB-MF with devaluation study)
	},
	lottery_N_frames: 35,
	durations: { //in ms
		// every trial:
		entranceMessage: 800,
		lotteryAnim: 3500,
		intervalBetweenLotteryAndOutcomeAnim: 2800,
		// manipulation:
		outcomeAnim: 2000,
		intervalBetweenOutcomeAndNextThing: 1000,
		// animations:
		costAnim: 1500,
		surface_disappearance: 700,
	},
	text: {
		// alerts, prompts etc:
		rewardContainerClearingMessage: 'The cargo spaceship has emptied the warehouse and it is now ready to store gold.',
		manipulationMessage: function (manipulationType) {
			if (manipulationType == 'devaluation') {
				return 'The warehouse is full!<br>It cannot store any more gold until the cargo spaceship empties it.';
			} else if (manipulationType == 'still_valued' || manipulationType == 'still_valued_post_deval' || manipulationType == 'still_valued_replacing_devaluation') { // i.e., 'still_valued'
				return 'The warehouse is half full...';
			}
		},
		confirmationCodeTextMessage: '\nPlease enter the following letters to confirm that you have read the message: ',
		realGameBegins: 'The real game starts now.<br>The gold you will accumulate from now on is worth real money.<br><br>Good Luck!',
		endExperiment: function (baselineAccumulatedReward) {
			return 'The game is over. Thank you for participating!' + '<br><br>' +
				'You managed to bring to earth '
				+ baselineAccumulatedReward // This was designed to replace the line below.
				// + logic.calculateReward(subData, app_settings.coinCollectionTask, dayToFinishExperiment)
				+ ' Gold units!'
		},
		noConnectionToEndExperiment: 'Unable to connect to the server.' + '<br><br>' +
			'Please verify you have network connection and try again.',
		dialog_coinCollection: "You found a gold cave. There are rocks and gold in the cave. Each attempt to collect an item (clicking) costs 10 gold units. The gold collected will be kept in the warehouse if it has room. Once you enter the cave, you'll have 5 seconds to stay there.",
		loadingDataError: 'There is a problem!' +
			'<br><br>' +
			'A. Please make sure you are connected to the internet.' +
			'<br>' +
			'B. Try closing the app and reentering.' +
			'<br><br>' +
			"If it is still not working, please contact [NAME] at: [PHONE NUMBER].",
	},
	coinCollectionTask: {
		includeRocks: true,
		duration: 5, // in seconds
		openningAnimTime: 1500, // in ms
		element_disappearing_time: 150, // in ms
		nStim: 30, // needs to be an even number here
		bg_img_path: 'images/cave.jpg',
		outcome_win_image_path: 'images/outcome_win.png',
		outcome_no_win_image_path: 'images/outcome_no_win.png',
		outcomeImageHeightWidthRatio: 325 / 349, // namely the height = 325 and width = 349	
		stimSizeProportionOfScreen: 0.15, // will determine the size (width and height of the stimuli)
		textSizeProportionOfScreenWidth: 0.15,
		ProportionOfScreenWidthToPlaceCounter: 0.9,
		ProportionOfScreenHeightToPlaceCounter: 0.05,
		counterTextColor: [0, 0, 255], // can be one value for gray, 3 for RGB, 4 to include alpha
		finishMessageTextColor: [0, 0, 255], // can be one value for gray, 3 for RGB, 4 to include alpha
		finishMessage: "Goodbye",
		costPerPress: 10, // for the winnings calculation at the end
		rewardPerCoinStash: () => app_settings.rewards.rewardConstantSum, // for the winnings calculation at the end
	},
	// Instructions and demo:
	allowInstructions: true, // for debugging purpose.
	allowDemo: true,
	demoCycle: {
		0: { isWin: true, whichManipulation: null, activateManipulation: false, isUnderManipulation: false, toHideOutcome: false, resetContainer: false, consumptionTest: false },
		1: { isWin: false, whichManipulation: null, activateManipulation: false, isUnderManipulation: false, toHideOutcome: false, resetContainer: false, consumptionTest: false },
		2: { isWin: false, whichManipulation: null, activateManipulation: false, isUnderManipulation: false, toHideOutcome: false, resetContainer: false, consumptionTest: true },
		3: { isWin: true, whichManipulation: 'still_valued', activateManipulation: true, isUnderManipulation: false, toHideOutcome: false, resetContainer: false, consumptionTest: false },
		4: { isWin: true, whichManipulation: 'devaluation', activateManipulation: true, isUnderManipulation: false, toHideOutcome: false, resetContainer: false, consumptionTest: false },
		5: { isWin: false, whichManipulation: null, activateManipulation: false, isUnderManipulation: false, toHideOutcome: true, resetContainer: true, consumptionTest: false },
	},
	demoCycleSupportingText: {
		0: {
			a: 'We prepared a demo for you with a virtual screen that simulates a smartphone.<br> Tap the app to launch your spaceship to a gold-seeking mission. First, you will see your spaceship landing, and in the top right corner, the cost of sending the spaceship to the mission will be displayed (-1).',
			b: 'Now tap the bottom half of the screen and then on the top half to remove the ice layer and enable the gold search. After a few seconds of searching, the outcome will be presented.',
			c: 'In this round you have found gold!<br>Immediately afterwards, the end message appears ("See you next time"). When this message appears, it means that the search result has been recorded and you can exit the app. To exit the app in this demo, tap the home button on the virtual smartphone.',
		},
		1: "Now you will enter (and exit) the app a few times and we will demonstrate different task components.<br> You can now enter the app and remove the ice layers.<br> This time you won't find gold (only worthless rocks).",
		2: 'In the next round you will encounter a cave rich in gold.<br>You will receive a message about this and then you will have 5 seconds inside it, during which you can collect from the items in the cave.',
		3: 'In the next entry we will demonstrate receiving a report that the warehouse is half full.',
		4: 'This time we will demonstrate receiving a report that the warehouse is full.',
		5: 'At the beginning of the next round you will receive a report that the cargo spaceship (the one that empties the warehouse on the gold planet every 24 hours) has emptied the warehouse.<br>In addition, it will be cloudy and you will not be able to see the result of your gold search.<br>*Here, too, you would have to wait for the end message so that the search result is recorded.',
	},
	instructionsFileName: 'instructions.html',
	n_instruction_pages: 24,
	lastInstructionsPageExplainsDemo: true,
	instructions_test_questions: {
		toRandomizeQuestions: false,
		dont_know_answer: "I don't know.",
		1: {
			question: 'Is there a cost to enter the app (that is, to try and find gold)?',
			correct_answer: 'Yes, it costs 1 gold unit.',
			distractor_1: 'There is no entry cost, there is a cost only on attempts to collect items in a cave.',
			distractor_2: 'Yes, it costs 15 gold units.',
			distractor_3: 'Yes, the cost varies each time.',
		},
		2: {
			question: 'Does the chance of finding gold vary at certain times?',
			correct_answer: 'No, the chance of finding gold is always the same.',
			distractor_1: 'The chance of finding gold changes all the time.',
			distractor_2: 'The chance of finding gold changes when it is cloudy and it is not possible to see if I found gold.',
			distractor_3: 'If I recently found a lot of gold, the chance of finding more gold is smaller and vice versa.',
		},
		3: {
			question: 'What happens if the warehouse is full?',
			correct_answer: 'It is not possible to accumulate any more gold that will be taken to Earth and converted into real money for me until the warehouse is emptied at the end of the day (at 5:00 AM).',
			distractor_1: 'I will need to directly and immediately send the gold to Earth.',
			distractor_2: 'This means that the game is over.',
			distractor_3: 'The warehouse cannot be filled completely but only partially.',
		},
		4: {
			question: 'What happens if the warehouse is partially full?',
			correct_answer: "Nothing, it's just an update. As long as the warehouse is not completely full, it is possible to continue accumulating gold in it.",
			distractor_1: "It's not something I would know about because there are no reports of the warehouse being only partially full.",
			distractor_2: 'It is not possible to accumulate any more gold that will be taken to Earth and converted into real money for me until the warehouse is emptied at the end of the day (at 5:00 AM).',
			distractor_3: 'I will need to directly and immediately send the gold to Earth.',
		},
		5: {
			question: 'What is the value of the gold piles I can find?',
			correct_answer: '15 gold units.',
			distractor_1: 'The amount varies and will be displayed each time accordingly.',
			distractor_2: '1 gold unit.',
			distractor_3: 'The amount varies and I have no way of knowing it.',
		},
		6: {
			question: 'After I enter the app, when can I exit it so that the search outcome will be counted for me?',
			correct_answer: 'When the end message (saying "See you next time") appears.',
			distractor_1: 'Immediately after I enter.',
			distractor_2: 'Immediately upon the presentation of the search outcome.',
			distractor_3: 'When clouds appear.',
		},
		7: {
			question: "What happens when the gold planet is cloudy and I can't see the search outcomes?",
			correct_answer: 'Everything continues exactly the same. There is no change except for the fact that I cannot see the search outcome.',
			distractor_1: 'The game is not available at these times so it is better to try again later.',
			distractor_2: 'There is no entry cost.',
			distractor_3: "I cannot acquire the gold in the warehouse.",
		},
		8: {
			question: 'How can I earn real money?',
			correct_answer: 'Just enter the app to search for gold. If I find gold and there is room in the warehouse, the gold will be taken to Earth and converted into real money. The more gold I acqire, the more money I will earn.',
			distractor_1: 'It is not possible to earn real money in the game.',
			distractor_2: 'Just enter the app to search for rocks. If I find rocks and there is room in the warehouse, the rocks will be taken to Earth and converted into real money.',
			distractor_3: 'Enter the app and wait as long as possible before I close it. The longer it is continuously open, the more I will earn.',
		},
		9: {
			question: 'How many entries can be made each day?',
			correct_answer: 'As much as desired, but at least 5 entries per day in order to keep the gold planet available (and with it the ability to continue accumulating gold).',
			distractor_1: 'As much as desired, but at least 2 entries per day in order to keep the gold planet available (and with it the ability to continue accumulating gold).',
			distractor_2: 'As much as desired, but at most 100 entries per day in order to keep the gold planet available (and with it the ability to continue accumulating gold).',
			distractor_3: 'As much as desired, but at most 300 entries per day in order to keep the gold planet available (and with it the ability to continue accumulating gold).',
		},
		10: {
			question: 'Which of the following is not true regarding the rich-in-gold caves that I may occasionally encounter?',
			correct_answer: "All of the answers are correct (except for 'I don't know').",
			distractor_1: 'I have only 5 seconds inside the cave, during which I can collect from the items placed in it.',
			distractor_2: 'Each attempt (click) to collect an item inside the cave costs 10 gold units.',
			distractor_3: 'The value of the gold and rock piles is equal to the value of the gold and rock piles in the regular gold searches.',
		},
		11: {
			question: 'What is the duration of the game?',
			correct_answer: 'The duration of the game is not predetermined. It can range from a few days to one month.',
			distractor_1: 'One day.',
			distractor_2: 'A week.',
			distractor_3: 'A month.',
		},
		// [replace_here_ with_a_number]: {
		// 	question: '',
		// 	correct_answer: '',
		// 	distractor_1: '',
		// 	distractor_2: '',
		// 	distractor_3: '',
		// },
	},
	// Meta stuff:
	instructions_HTML_title: 'Instructions',
	instructions_main_HTML_element: "instructions_iframe",
	App_HTML_title: 'Space Gold',
	App_main_HTML_element: "main_container",
	dataVarList: ["serial", "uniqueEntryID", "subId", "group", "day", "isWin", "reward", "cost", "baselineAccumulatedReward", "resetContainer", "resetContainerConfirmationTime", "manipulationToday", "activateManipulation", "isUnderManipulation", "hideOutcome", "isFirstTime", "startTime", "press1Time", "press2Time", "outcomeTime", "endTime", "manipulationAlertTime", "showInstructions", "instructionsStartedFlag", "completedInstructions", "isDemo", "demoTrialNum", "isDialogOn", "coin_task_finish_status", "endExperiment", "manipulationConfirmationTime", "foundCaveAlertTime", "foundCaveConfirmationTime", "localSessionId"],
	// NOTE: the completedInstructions is assigned during the instructions upon success.
}
