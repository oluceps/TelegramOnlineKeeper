use eyre::{Result, WrapErr};
use grammers_client::{Client, Config, SignInError};
use grammers_session::Session;
use grammers_tl_types as tl;
use std::io;
use std::io::{BufRead, Write};
use tl::{
    enums,
    types::{self},
};
use tokio::runtime;

fn prompt(message: &str) -> Result<String> {
    let stdout = io::stdout();
    let mut stdout = stdout.lock();
    stdout.write_all(message.as_bytes())?;
    stdout.flush()?;

    let stdin = io::stdin();
    let mut stdin = stdin.lock();

    let mut line = String::new();
    stdin.read_line(&mut line)?;
    Ok(line)
}

async fn async_main() -> Result<()> {
    use std::env::var;

    let api_id = var("API_ID")
        .wrap_err("error getting $API_ID")?
        .parse::<i32>()
        .wrap_err("error parsing API_ID to i32")?;

    let api_hash = var("API_HASH").wrap_err("error getting $API_HASH")?;

    use std::path::PathBuf;
    let session_file_path: PathBuf = if let Ok(val) = var("SESSION_FILE") {
        PathBuf::from(val)
    } else {
        PathBuf::from("user.session")
    };

    let check_interval = if let Ok(val) = var("CHECK_INTERVAL") {
        val.parse::<u64>()?
    } else {
        16 // default for 16 sec, since telegram flush the online state per 5 min.
           // but it will recalculate everytime the window got inactive.
    };

    let pos = if let Ok(val) = var("POSSIBLE") {
        val.parse::<f32>()?
    } else {
        0.05 // when online randomly offline
    };

    println!("Connecting to Telegram...");

    let client = Client::connect(Config {
        session: Session::load_file_or_create(session_file_path.clone())?,
        api_id,
        api_hash,
        params: Default::default(),
    })
    .await?;

    println!("Connected!");

    if !client.is_authorized().await? {
        println!("Signing in...");
        let phone = prompt("Enter your phone number (international format): ")?;
        let token = client.request_login_code(&phone).await?;
        let code = prompt("Enter the code you received: ")?;
        let signed_in = client.sign_in(&token, &code).await;
        match signed_in {
            Err(SignInError::PasswordRequired(password_token)) => {
                // Note: this `prompt` method will echo the password in the console.
                let hint = password_token.hint().unwrap();
                let prompt_message = format!("Enter the password (hint {}): ", &hint);
                let password = prompt(prompt_message.as_str())?;

                client
                    .check_password(password_token, password.trim())
                    .await?;
            }
            Ok(_) => (),
            Err(e) => panic!("{}", e),
        };
        println!("Signed in!");
        match client.session().save_to_file(session_file_path) {
            Ok(_) => {}
            Err(e) => {
                println!(
                    "NOTE: failed to save the session, will sign out when done: {}",
                    e
                );
            }
        }
    }

    loop {
        use tokio::time;

        time::sleep(time::Duration::from_secs(check_interval)).await;

        let tl::enums::users::UserFull::Full(types::users::UserFull { users, .. }) = client
            .invoke(&tl::functions::users::GetFullUser {
                id: tl::enums::InputUser::UserSelf,
            })
            .await?;

        if let tl::enums::User::User(types::User { status, .. }) =
            users.get(0).expect("never empty")
        {
            match status {
                Some(enums::UserStatus::Offline(_)) => {
                    dbg!(
                        client
                            .invoke(&tl::functions::account::UpdateStatus { offline: false })
                            .await?
                    );
                }
                Some(enums::UserStatus::Online(_)) => {
                    let rand = fastrand::f32().abs() % 1.0;

                    if rand <= pos {
                        dbg!(
                            client
                                .invoke(&tl::functions::account::UpdateStatus { offline: true })
                                .await?
                        );
                    }
                }
                _ => (),
            }
        } else {
            unreachable!()
        };
    }
}

fn main() -> Result<()> {
    runtime::Builder::new_current_thread()
        .enable_all()
        .build()?
        .block_on(async_main())
}
