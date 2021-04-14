pragma solidity ^0.5.9;

contract kyc {
	// Struct customer
	// uname - username of the customer
	// dataHash - customer data
	// rating - rating given to customer given based on regularity
	// upvotes - number of upvotes received from banks
	// bank - address of bank that validated the customer account
        // password - password of the customer

	struct Customer {
		string uname;
		string dataHash;
		uint rating;
		uint upvotes;
		address bank;
		string password;
	}

	// Struct Organisation
	// name - name of the bank/organisation
	// ethAddress - ethereum address of the bank/organisation
	// rating - rating based on number of valid/invalid verified accounts
	// KYC_count - number of KYCs verified by the bank/organisation

	struct Organisation {
		string name;
		address ethAddress;
		uint rating;
		uint KYC_count;
		string regNumber;
	}

	struct Request {
		string uname;
		address bankAddress;
		bool isAllowed;
	}

	// list of all customers

	Customer[] Customers;

	// lst of all Banks/Organisations

	Organisation[] allOrgs;

	Request[] allRequests;
	function ifAllowed(string memory Uname, address bankAddress) public payable returns(bool) {
		for(uint i=0; i < allRequests.length; ++i) {
			if(stringsEqual(allRequests[i].uname, Uname) && allRequests[i].bankAddress == bankAddress && allRequests[i].isAllowed) {
				return true;
			}
		}
		return false;
	}

	function getBankRequests(string memory Uname, uint ind) public payable returns(address) {
		uint j = 0;
		for(uint i = 0; i<allRequests.length; ++i) {
			if(stringsEqual(allRequests[i].uname, Uname) && j ==  ind && allRequests[i].isAllowed == false) {
				return allRequests[i].bankAddress;
			}
			j ++;
		}
		return "contract address input here";
	}

	function addRequest(string memory Uname, address bankAddress) public payable {
		for(uint i=0; i < allRequests.length; ++i) {
			if(stringsEqual(allRequests[i].uname, Uname) && allRequests[i].bankAddress == bankAddress) {
				return;
			}
		}
		allRequests.length ++;
		allRequests[allRequests.length - 1] = Request(Uname, bankAddress, false);
	}

	function allowBank(string memory Uname, address bankAddress, bool ifallowed) public payable {
		for(uint i = 0; i < allRequests.length; ++i){
			if(stringsEqual(allRequests[i].uname, Uname) && allRequests[i].bankAddress == bankAddress) {
		if(ifallowed) {
			allRequests[i].isAllowed = true;
		    } else {
			  for(uint j=i; j<allRequests.length-2; ++j) {
			  allRequests[i] = allRequests[i+1];
			}
			  allRequests.length --;
		    }
		    return;
	        }
	    } 
	}


   // internal function to compare strings

      function stringsEqual(string storage _a, string memory _b) internal returns (bool) {
      	bytes storage a = bytes(_a);
      	bytes memory b = bytes(_b);
      	if (a.length != b.length)
      	   return false;
      	   // @todo unroll this loop
      	   for (uint i = 0; i < a.length; i++)
      	   {
      	   	if (a[i] != b[i])
      	   	   return false;
      	    }
      	    return true;
        }
        //function to check access rights of transaction request sender

        function isPartOfOrg() public payable returns(bool) {
        	for (uint i = 0; i < allOrgs.length; ++ i) {
        		if(allOrgs[i].ethAddress == msg.sender)
        		return true;
        	}
        	return false;
        }

        // function that adds an organisation to the network
        // returns 0 if successful
        // returns 7 if no access rights to transaction request sender
        // no check on access rights if network strength is zero
        function addBank(string memory uname, address eth, string memory regNum) public payable returns (uint) {
        	if(allOrgs.length == 0 || isPartOfOrg()) {
        		allOrgs.length ++;
        		allOrgs[allOrgs.length - 1] = Organisation(uname, eth, 200, 0, regNum);
        		return 0;
        	}
        	return 7;
        }
        //function that removes an organisation from the network
        // returns 0 if successful
        // returns 7 if no access rights to transaction request sender
        // returns 1 if organisation to be removed not part of network

        function removeBank(address eth) public payable returns(uint) {
        	if(!isPartOfOrg())
        	return 7;
        	for(uint i = 0; i < allOrgs.length; ++ i) {
        		if(allOrgs[i].ethAddress == eth) {
        			for(uint j = i+1; j < allOrgs.length; ++ j) {
        				allOrgs[i-1] = allOrgs[i];
        			}
        			allOrgs.length --;
        			return 0;
        		}
        	}
        	return 1;
        }

        // function to add a customer profile to the database
        //returns 0 if successful
        // returns 7 if no access rights to transaction request sender
        // returns 1 if size limit of the database is reached
        // returns 2 if the customer is already in the network

        function addCustomer(string memory Uname, string memory DataHash) public payable returns(uint) {
        	if(!isPartOfOrg())
        	return 7;
        	// throw error if username already in use
        	for (uint i = 0; i < Customers.length; ++ i) {
        		if(stringsEqual(Customers[i].uname, Uname))
        		return 2;
        	}
        	Customers.length ++;
        	//throw error if there is overflow in unit
        	if(Customers.length < 1)
        	return 1;
        	Customers[Customers.length-1] = Customer(Uname, DataHash, 100, 0, msg.sender, "null");
        	updateRating(msg.sender,true);
        	return 0;
        }

        // function to remove fraudlent customer profile from the database
        // returns 0 if successful
        // returns 7 if no access rights to transaction request sender
        // returns 1 if Customer profile not in database

        function removeCustomer(string memory Uname) public payable returns(uint) {
        	if(!isPartOfOrg())
        	return 7;
        	for(uint i = 0; i < Customers.length; ++ i) {
        		if(stringsEqual(Customers[i].uname, Uname)) {
        			address a = Customers[i].bank;
        			for(uint j = i+1; j < Customers.length; ++ j) {
        				Customers[i-1] = Customers[i];
        			}
        			Customers.length --;
        			updateRating(a,false);
        			//updateRating(msg.sender, true);
        			return 0;
        		}
        	}
        	//throw error if uname not found
        	return 1;
        }

        // function to modify a customer profile in the database
        // returns 0 if successful
        // returns 7 if noa ccess rights to transaction request sender
        // returns 1 if customer profile not in database

        function modifyCustomer(string memory Uname, string memory DataHash) public payable returns(uint) {
        	if(!isPartOfOrg())
        	return 7;
        	for (uint i = 0; i < Customers.length; ++ i) {
        		if(stringsEqual(Customers[i].uname, Uname)) {
        			Customers[i].dataHash = DataHash;
        			Customers[i].bank = msg.sender;
        			return 0;
        		}
        	}
        	// throw error if uname not found
        	return 1;
        }
        // function to return customer profile data

        function viewCustomer(string memory Uname) public payable returns(string memory) {
        	if(!isPartOfOrg())
        	return "Access denied!";
        	for(uint i = 0; i < Customers.length; ++ i) {
        		if(stringsEqual(Customers[i].uname, Uname)) {
        			return Customers[i].dataHash;
        		}
        	}
        	return "Customer not found in database!";
        }

        //function to modify customer rating

        function updateRatingCustomer(string memory Uname, bool ifIncrease) public payable returns(uint) {
        	for(uint i = 0; i < Customers.length; ++i) {
        		if(stringsEqual(Customers[i].uname, Uname)) {
        			//update rating
        			if(ifIncrease) {
        				Customers[i].upvotes ++;
        				Customers[i].rating += 100/ (Customers[i].upvotes);
                        if(Customers[i].rating > 500) {
                            Customers[i].rating = 500;
                        }
        			}		
                else {
                    Customers[i].upvotes --;
                    Customers[i].rating -= 100/(Customers[i].upvotes + 1);
                    if(Customers[i].rating < 0) {
                        Customers[i].rating = 0;
                    }
                }
                return 0;
        	}
        }
        //throw error if bank not found
        return 1;
    }

    // function to update organisation rating
    // bool true indicates a successful addition of KYC profile
    // false indicates detection of a fraudlent profile

    function updateRating(address bankAddress, bool ifAdded) public payable returns(uint) {
        for(uint i = 0; i < allOrgs.length; ++ i) {
            if(allOrgs[i].ethAddress == bankAddress) {
                // update rating
                if(ifAdded) {
                    allOrgs[i].KYC_count ++;
                    allOrgs[i].rating += 100/(allOrgs[i].KYC_count);
                    if(allOrgs[i].rating > 500) {
                        allOrgs[i].rating = 500;
                    }
                }
                else {
                    allOrgs[i].KYC_count --;
                    allOrgs[i].rating -= 100/ (allOrgs[i].KYC_count);
                    if(allOrgs[i].rating > 500) {
                        allOrgs[i].rating = 500;
                    }
                }
                return 0;
            }
        }
        // throw error if bank not found
        return 1;
    }

    // function to validate bank log in
    // returns null if username or password not correct
    // returns bank name if correct

    function checkBank(string memory Uname, address password) public payable returns(string memory) {
        for(uint i = 0; i < allOrgs.length; ++ i) {
            if(allOrgs[i].ethAddress == password && stringsEqual(allOrgs[i].name, Uname)) {
                return "0";
            }
        }
        return "null";
    }

    function checkCustomer(string memory Uname, string memory password) public payable returns(bool) {
        for (uint i = 0; i < Customers.length; ++ i) {
            if(stringsEqual(Customers[i].uname, Uname) && stringsEqual(Customers[i].password, password)) {
                return true;
            }
            if(stringsEqual(Customers[i].uname, Uname)) {
                return false;
            }
        }
        return false;
    }

    function setPassword(string memory Uname, string memory password) public payable returns(bool) {
        for(uint i = 0; i < Customers.length; ++ i) {
            if(stringsEqual(Customers[i].uname, Uname) && stringsEqual(Customers[i].password, "null")) {
                Customers[i].password = password;
                return true;
            }
        }
        return false;
    }

    // All getter functions

    function getBankName(address ethAcc) public payable returns(string memory) {
        for(uint i = 0; i < allOrgs.length; ++ i) {
            if(allOrgs[i].ethAddress == ethAcc) {
                return allOrgs[i].name;
            }
        }
        return "null";
    }

    function getBankEth(string memory uname) public payable returns(address) {
        for(uint i = 0; i < allOrgs.length; ++ i) {
            if(stringsEqual(allOrgs[i].name, uname)) {
                return allOrgs[i].ethAddress;
            }
        }
        return "contract address input here";
    }

    function getCustomerBankName(string memory Uname) public payable returns(string memory) {
        for(uint i = 0; i < Customers.length; ++ i) {
           if(stringsEqual(Customers[i].uname, Uname)) {
            return getBankName(Customers[i].bank);
           }
        }
    }

    function getBankReg(address ethAcc) public payable returns(string memory) {
        for(uint i = 0; i < allOrgs.length; ++ i) {
            if(allOrgs[i].ethAddress == ethAcc) {
                return allOrgs[i].regNumber;
            }
        }
        return "null";
    }

    function getBankKYC(address ethAcc) public payable returns(uint) {
        for(uint i = 0; i < allOrgs.length; ++ i) {
            if(allOrgs[i].ethAddress == ethAcc) {
                return allOrgs[i].KYC_count;
            }
        }
        return 0;
    }

    function getBankRating(address ethAcc) public payable returns(uint) {
        for(uint i = 0; i < allOrgs.length; ++ i) {
            if(allOrgs[i].ethAddress == ethAcc) {
                return allOrgs[i].rating;
            }
        }
        return 0;
    }

    function getCustomerBankRating(string memory Uname) public payable returns(uint) {
        for(uint i = 0; i < Customers.length; ++ i) {
            if(stringsEqual(Customers[i].uname, Uname)) {
                return getBankRating(Customers[i].bank);
            }
        }
    }

    function getCustomerRating(string memory Uname) public payable returns(uint) {
        for(uint i = 0; i < Customers.length; ++ i) {
            if (stringsEqual(Customers[i].uname, Uname)) {
                return Customers[i].rating;
            }
        }
        return 0;
    }
}
