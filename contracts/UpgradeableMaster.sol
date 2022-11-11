// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.6;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Config.sol";
import "./ZkBNBOwnable.sol";
import "./Storage.sol";

/// @title Interface of the upgradeable master contract (defines notice period duration and allows finish upgrade during preparation of it)
/// @author ZkBNB Team
contract UpgradeableMaster is ZkBNBOwnable, Config, Storage {
    using SafeMath for uint256;
    /// @dev Configurable notice period
    uint256 public constant UPGRADE_NOTICE_PERIOD = 4 weeks;
    /// @dev Shortest notice period
    uint256 public constant SHORTEST_UPGRADE_NOTICE_PERIOD = 0;

    uint256 public constant SECURITY_COUNCIL_MEMBERS_NUMBER = 3;

    /// @notice Notice period changed
    event NoticePeriodChange(uint256 newNoticePeriod);

    address[] securityCouncilMembers;

    /// @dev Flag indicates that upgrade preparation status is active
    /// @dev Will store false in case of not active upgrade mode
    bool internal upgradePreparationActive;

    /// @dev Upgrade preparation activation timestamp (as seconds since unix epoch)
    /// @dev Will be equal to zero in case of not active upgrade mode
    uint256 internal upgradePreparationActivationTime;

    /// @dev Upgrade notice period, possibly shorten by the security council
    uint256 internal approvedUpgradeNoticePeriod;

    /// @dev Upgrade start timestamp (as seconds since unix epoch)
    /// @dev Will be equal to zero in case of not active upgrade mode
    uint256 internal upgradeStartTimestamp;

    /// @dev Stores boolean flags which means the confirmations of the upgrade for each member of security council
    /// @dev Will store zeroes in case of not active upgrade mode
    mapping(uint256 => bool) internal securityCouncilApproves;
    uint256 internal numberOfApprovalsFromSecurityCouncil;

    constructor(address[3] memory _securityCouncilMembers)
        ZkBNBOwnable(msg.sender)
    {
        securityCouncilMembers = _securityCouncilMembers;

        approvedUpgradeNoticePeriod = SHORTEST_UPGRADE_NOTICE_PERIOD;
        emit NoticePeriodChange(approvedUpgradeNoticePeriod);
    }

    /// UpgradeableMaster functions

    // Upgrade functional
    /// @notice Shortest Notice period before activation preparation status of upgrade mode
    ///         Notice period can be set by secure council
    function getNoticePeriod() external view returns (uint256) {
        return approvedUpgradeNoticePeriod;
    }

    /// @notice Notification that upgrade notice period started
    /// @dev Can be external because Proxy contract intercepts illegal calls of this function
    function upgradeNoticePeriodStarted() external {
        upgradeStartTimestamp = block.timestamp;
    }

    /// @notice Notification that upgrade preparation status is activated
    /// @dev Can be external because Proxy contract intercepts illegal calls of this function
    function upgradePreparationStarted() external {
        upgradePreparationActive = true;
        upgradePreparationActivationTime = block.timestamp;
        // Check if the approvedUpgradeNoticePeriod is passed
        require(
            block.timestamp >=
                upgradeStartTimestamp.add(approvedUpgradeNoticePeriod)
        );
    }

    /// @notice Notification that upgrade canceled
    /// @dev Can be external because Proxy contract intercepts illegal calls of this function
    function upgradeCanceled() external {
        clearUpgradeStatus();
    }

    /// @notice Notification that upgrade finishes
    /// @dev Can be external because Proxy contract intercepts illegal calls of this function
    function upgradeFinishes() external {
        clearUpgradeStatus();
    }

    /// @notice Checks that contract is ready for upgrade
    /// @return bool flag indicating that contract is ready for upgrade
    function isReadyForUpgrade() external view returns (bool) {
        return !desertMode;
    }

    function upgrade(bytes calldata upgradeParameters) external {}

    /// @dev When upgrade is finished or canceled we must clean upgrade-related state.
    function clearUpgradeStatus() internal {
        upgradePreparationActive = false;
        upgradePreparationActivationTime = 0;
        approvedUpgradeNoticePeriod = SHORTEST_UPGRADE_NOTICE_PERIOD;
        emit NoticePeriodChange(approvedUpgradeNoticePeriod);
        upgradeStartTimestamp = 0;
        for (uint256 i = 0; i < securityCouncilMembers.length; ++i) {
            securityCouncilApproves[i] = false;
        }
        numberOfApprovalsFromSecurityCouncil = 0;
    }

    // TODO
    uint256 internal constant SECURITY_COUNCIL_2_WEEKS_THRESHOLD = 3;
    uint256 internal constant SECURITY_COUNCIL_1_WEEK_THRESHOLD = 2;
    uint256 internal constant SECURITY_COUNCIL_3_DAYS_THRESHOLD = 1;

    function cutUpgradeNoticePeriod() external {
        // TODO: check zkBNB desertMode
        // requireActive();

        for (uint256 id = 0; id < securityCouncilMembers.length; ++id) {
            if (securityCouncilMembers[id] == msg.sender) {
                require(upgradeStartTimestamp != 0);
                require(securityCouncilApproves[id] == false);
                securityCouncilApproves[id] = true;
                numberOfApprovalsFromSecurityCouncil++;

                if (
                    numberOfApprovalsFromSecurityCouncil ==
                    SECURITY_COUNCIL_2_WEEKS_THRESHOLD
                ) {
                    if (approvedUpgradeNoticePeriod > 2 weeks) {
                        approvedUpgradeNoticePeriod = 2 weeks;
                        emit NoticePeriodChange(approvedUpgradeNoticePeriod);
                    }
                } else if (
                    numberOfApprovalsFromSecurityCouncil ==
                    SECURITY_COUNCIL_1_WEEK_THRESHOLD
                ) {
                    if (approvedUpgradeNoticePeriod > 1 weeks) {
                        approvedUpgradeNoticePeriod = 1 weeks;
                        emit NoticePeriodChange(approvedUpgradeNoticePeriod);
                    }
                } else if (
                    numberOfApprovalsFromSecurityCouncil ==
                    SECURITY_COUNCIL_3_DAYS_THRESHOLD
                ) {
                    if (approvedUpgradeNoticePeriod > 3 days) {
                        approvedUpgradeNoticePeriod = 3 days;
                        emit NoticePeriodChange(approvedUpgradeNoticePeriod);
                    }
                }

                break;
            }
        }
    }
}
