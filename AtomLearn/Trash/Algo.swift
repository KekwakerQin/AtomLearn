//class Solution {
//    func rob(_ nums: [Int]) -> Int {
//        guard nums.count > 1 else { return nums[0] }
//        if nums.count == 2 {
//            return max(nums[0], nums[1])
//        }
//        var dp: [Int] = []
//        dp.append(nums[0])
//        dp.append(max(nums[0], nums[1]))
//        for i in 2..<nums.count {
//            if dp[i-1] > nums[i] + dp[i-2] {
//                dp.append(dp[i-1])
//            } else {
//                if i == 3 {
//                    if nums[3] + dp[0] > dp[i - 1] { return nums[3] + dp[0] }
//                }
//                dp.append(nums[i] + dp[i-2])
//            }
//        }
//        
//        return dp[dp.count - 1]
//    }
//}


