angular.module('aepi-fantasy').controller('AdminParsingController', function($scope, $location, $routeParams, $resource) {

    // Public variables
    $scope.playerMappings = getPlayerMappings();
    $scope.createMappingMessage = '';
    $scope.mapping = {}
    $scope.baseball = {}
    $scope.football = {}

    // Private variables
    var api_token = null
    var Token = $resource('/api/parser/token')
    var token = Token.get(function() {
        api_token = token.token;
    });
    

    // Public variables
    $scope.parsers = [
        {
            name:"Standings",
            id: "standings"
        },{
            name:"Football Scoreboard",
            id: "scoreboard"
        },{
            name:"Football Draft",
            id: "draft/football"
        },{
            name:"Football Transactions",
            id:"transaction/football"
        },{
            name:"Baseball Draft",
            id: 'draft/baseball'
        },{
            name:"Baseball Transactions",
            id:"transaction/baseball"
        },{
            name:"Baseball Players",
            id:"players/baseball"
        },{
            name:"Calculate Team Ratings",
            id:'teamnames'
        }
    ]

    // Watches

    // Public Functions
    $scope.runParsingTask = function(parser) {
        parser.submitted = true

        var body = {
            token: api_token
        }

        var Parser = $resource('/api/parser/' + parser.id + '/run');
        Parser.save(body, function(response) {
            parser.confirmed = true
            if(response.error) {
                parser.message = response.error
            } else if(response.success) {
                parser.message = "Parsing complete"
            }
        })
    }

    $scope.createMapping = function() {
        var PlayerMapping = $resource('/api/admin/playerMapping');
        PlayerMapping.save($scope.mapping, function(response) {
            $scope.createMappingMessage = 'Mapping Created.'
            $scope.playerMappings.push({espn_name: $scope.mapping.espnName, twitter_name: $scope.mapping.twitterName})
            $scope.mapping = {};
        })
    }

    $scope.deleteMapping = function(mapping) {
        mapping.deleteSubmitted = true;
        var PlayerMapping = $resource('/api/admin/playerMapping/' + mapping.espn_name);
        PlayerMapping.remove(function(response) {
            if(response.success) {
                mapping.deleteConfirmed = true;
            } else {
                mapping.deleteSubmitted = false;
            }
        })
    }

    // Private Functions
    function getPlayerMappings() {
        var PlayerMapping = $resource('/api/admin/playerMapping')
        var results = PlayerMapping.query();

        return results;
    }
});