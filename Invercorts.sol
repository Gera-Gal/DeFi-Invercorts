pragma experimental ABIEncoderV2;
pragma solidity ^0.5.0;

contract InvestContract {
    
    struct Payment{
        uint amount;
        address sender;
        address receiver;
        bool delivered;     //Orden de transferencia completada, monto abonado a Receptor
    }
    
    event PaymentSent(bytes32 _hash);
    
    mapping(address => uint256) public balanceOf;           //Balances de las cuentas
    mapping(bytes32=>Payment) public availablePayments;     //Datos de pagos
    address public owner;
    
    constructor (uint256 initialSupply) public {
        owner = msg.sender;
        balanceOf[owner] = initialSupply;
    }
    
    function getBalance(address account) public view returns(uint256 balance) {
        require(msg.sender==account,"Solo puede consultar su propio saldo");    //Esta consulta de saldo es para el front
        return balanceOf[account];
    }
    
    //Inversores e Invercorts pueden agregar fondos
    function mint(address receiver) public payable returns(bytes32 _hash) {
        require(msg.value>0,"No vienen fondos");
        require(msg.value < 1e60,"Monto de transferencia no permitido");
        uint _amount = msg.value;
        bytes32 hash = keccak256(abi.encodePacked(msg.sender,receiver,_amount));
        availablePayments[hash]=Payment(_amount,msg.sender,receiver,false);
        emit PaymentSent(hash);
        balanceOf[receiver] += _amount;
        return hash;
    }

    //Inversores e Invercorts pueden transferir
    function issue(address receiver) public payable returns(bytes32 _hash) {
        require(msg.value>0,"No vienen fondos");
        require(balanceOf[msg.sender]>=msg.value,"No cuenta con saldo suficiente");
        require(balanceOf[receiver]+msg.value>=balanceOf[receiver],"Monto de transferencia no permitido");
        uint _amount = msg.value;
        bytes32 hash = keccak256(abi.encodePacked(msg.sender,receiver,_amount));
        availablePayments[hash]=Payment(_amount,msg.sender,receiver,false);
        emit PaymentSent(hash);
        balanceOf[msg.sender] -= _amount;
        return hash;
    }

    //Siguiendo el patrón de retiro, el receptor completa la transferencia y los balances se actualizan en el contrato
    function withdraw(bytes32 _hash) public {   
        require(msg.sender==availablePayments[_hash].receiver,"Solo puede retirar el receptor");
        require(availablePayments[_hash].delivered==false,"Pago ya entregado");
        availablePayments[_hash].delivered=true;
        msg.sender.transfer(availablePayments[_hash].amount);
        balanceOf[msg.sender] += availablePayments[_hash].amount;
    }
}