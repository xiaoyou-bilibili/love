use chrono::{FixedOffset, NaiveDate, TimeZone};

pub fn naive_date_to_timestamp(date: NaiveDate) -> i64 {
    let datetime = date.and_hms_opt(0, 0, 0).unwrap();
    let bj = FixedOffset::east_opt(8 * 3600).unwrap();
    bj.from_local_datetime(&datetime).unwrap().timestamp()
}

