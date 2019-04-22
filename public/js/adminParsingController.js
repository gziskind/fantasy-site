angular.module('aepi-fantasy').controller('AdminParsingController', function($scope, $location, $routeParams, $resource) {

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
            name:"Baseball Draft",
            id: 'draft/baseball'
        },{
            name:"Baseball Transactions",
            id:"transaction/baseball"
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

    // Private Functions
});