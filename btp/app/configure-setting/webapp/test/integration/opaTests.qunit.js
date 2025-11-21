sap.ui.require(
    [
        'sap/fe/test/JourneyRunner',
        'configuresetting/test/integration/FirstJourney',
		'configuresetting/test/integration/pages/SettingsList',
		'configuresetting/test/integration/pages/SettingsObjectPage'
    ],
    function(JourneyRunner, opaJourney, SettingsList, SettingsObjectPage) {
        'use strict';
        var JourneyRunner = new JourneyRunner({
            // start index.html in web folder
            launchUrl: sap.ui.require.toUrl('configuresetting') + '/index.html'
        });

       
        JourneyRunner.run(
            {
                pages: { 
					onTheSettingsList: SettingsList,
					onTheSettingsObjectPage: SettingsObjectPage
                }
            },
            opaJourney.run
        );
    }
);