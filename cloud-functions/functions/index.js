//Imports the Firebase Cloud Functions and Firebase Admin SDKs
const functions = require('firebase-functions');
const admin = require('firebase-admin');

//Initializes the admin SDK
admin.initializeApp(functions.config().firebase);

//Defines the grillOrderChange function to be called every time the path below is written to
exports.grillOrderChange = functions.database.ref('/Grills/{grillID}/Orders/{orderID}').onWrite(event => {
	if (!event.data.exists()) { //Checks that order exists (onWrite is called by deletions)
		console.log("No Data Exists (Order Deleted) - No Action Taken");

	} else if(event.data.val().orderStatus != 2) { //Checks that orderStatus is 2 (ready status)
		//If it isn't 2, but is 0 then we know the order was just placed and should increment the orderNumCount
		if (event.data.val().orderStatus == 0) {
			var countRef = event.data.ref.parent.parent.child('OrderNumCount');
			//Uses transactions in the case of multiple orders placed at the same time.
			var count;
		    countRef.transaction(function(current) { //Transaction sets orderNumCount
	            var newCount = (parseInt(current) || 0) +1;
		    	if(newCount >= 100) {
		    		newCount = 1;
		    	}
		   		count = newCount;
		    	return newCount;
			}).then(()=>{
				console.log('Setting OrderNum to: ',count);
				//Sets the orderNum in the actual order once the orderNum counter is sucessfully incremented
				admin.database().ref('/Orders/'+event.params.orderID+'/orderNum').set(count);
			});
		} else {
  			console.log('OrderStatus not set to ready and not set to orderPlaced - No Action Taken');
  		}

	} else if (!event.data.val().pushToken) { //Checks that a pushToken exists, if not returns
		console.error("PushToken does not exist (DB/Client Error ??) - No Action Taken");
		
	} else { //Data exists, push token exists, and orderStatus == 2, so should send food is ready push notification
	    //Creates the payload for the notification
	    let payload = {
	        notification: {
	            title: 'Hey!',
	            body: "Your Food is Ready!",
	            sound: 'default',
	            badge: '1'
	        }
	    };

	    let token = event.data.val().pushToken;
	    console.log('Notifying token: ',token);
	    return admin.messaging().sendToDevice([token], payload).then(response => {
	        //check if there was an error.
	        const error = response.results[0].error;
	        if (error) {
	        	console.error('Failure sending notification to', token, error);
	        }
		});
	}
});
