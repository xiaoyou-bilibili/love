use chrono::{FixedOffset, NaiveDate, TimeZone};

// NaiveDate转时间戳
pub fn naive_date_to_timestamp(date: NaiveDate) -> i64 {
    let datetime = date.and_hms_opt(0, 0, 0).unwrap();
    let bj = FixedOffset::east_opt(8 * 3600).unwrap();
    bj.from_local_datetime(&datetime).unwrap().timestamp()
}

// 判断两个区间是否重叠，如果两个区间的最大值中的较小值大于等于最小值中的较大值，那么这两个区间就有重叠
pub fn is_overlap(a: (i64, i64), b: (i64, i64)) -> bool {
    let max_start = a.0.max(b.0);
    let min_end = a.1.min(b.1);
    max_start <= min_end
}