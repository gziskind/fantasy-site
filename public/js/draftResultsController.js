angular.module('aepi-fantasy').controller('DraftResultsController', function($scope, $location, $routeParams, $resource) {

    // Public variables
    $scope.year = $routeParams.year;
    $scope.draft = []
    $scope.users = []
    $scope.positions = [];
    $scope.currentYear = new Date().getFullYear();
    $scope.selectedDraftType = 'pick';
    $scope.orderByField = 'pick'

    // Private Variables
    var positionOrder = ["C","1B","2B","SS","3B","OF","DH","SP","RP","QB","RB","WR","TE","K","D"]

    // Public Functions
    $scope.sortPosition = function(position) {
        return positionOrder.indexOf(position)
    }

    $scope.changeField = function(column, reverse) {
        if($scope.orderByField != column) {
            $scope.orderByField = column;
            console.info(reverse)
            $scope.reverseSort = !!reverse;
        } else {
            $scope.reverseSort = !$scope.reverseSort;
        }
    }
    
    $scope.sortStatus = function(column) {
        if($scope.orderByField == column) {
            if($scope.reverseSort) {
                return 'fa-sort-up';
            } else {
                return 'fa-sort-down';
            }
        } else {
            return '';
        }
    }

    $scope.positionField = function(pick) {
        return positionOrder.indexOf(pick.position)
    }

    // Watches
    $scope.$watch('year', updateDraft);

    // Private Functions
    function updateDraft(newValue, oldValue) {
        var sport = $scope.$parent.getSportType()
        var Draft = $resource('/api/' + sport + '/draft/:year')
        var value = Draft.query({year: newValue}, function(){
            $scope.draft = value
            var usersAndPositions = getUniqueUsersAndPositions(value)
            $scope.users = usersAndPositions.users;
            $scope.positions = usersAndPositions.positions;
        });
    }

    function getUniqueUsersAndPositions(picks) {
        var users = {};
        var positions = {};
        for(var c = 0; c < picks.length; c++) {
            users[picks[c].user] = 1
            positions[picks[c].position] = 1
        }

        return {
            users: Object.keys(users),
            positions: Object.keys(positions)
        };
    }
});