-- Recruit-A-Friend links made between accounts on the same IP address record that address,
-- so RecruitAFriend.SharedAddressLinks can cap how many such links one address holds.
ALTER TABLE `raf_accounts`
  ADD COLUMN `shared_address` VARCHAR(45) DEFAULT NULL,
  ADD KEY `shared_address` (`shared_address`);
