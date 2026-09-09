require "application_system_test_case"

class PicksTest < ApplicationSystemTestCase
  def setup
    @user = create_signed_in_user(username: "uriel")
    sign_in_as(@user)
    @other_user = User.create!(username: "alice")
    @track = Track.create!(
      spotify_id: "track_abc",
      name: "Test Song",
      artist_name: "Test Artist",
      duration_ms: 300_000
    )
    @public_epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Public Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    @private_epic = Epic.create!(
      user: @other_user,
      track: create_track,
      title: "Private Epic",
      start_time: 100_000,
      end_time: 200_000,
      visibility: :private
    )
  end

  test "User can pick an epic from epic page" do
    visit epic_path(@public_epic)

    click_button "Pick this Epic"

    assert_text "Epic foi pickado!"
    assert_text "1 Pick"
  end

  test "User can unpick an epic from epic page" do
    visit epic_path(@public_epic)
    click_button "Pick this Epic"
    assert_text "1 Pick"

    click_button "Picked ✓ — Unpick"

    assert_text "Pick desfeito."
    assert_text "0 Picks"
    # Volta a oferecer o Pick, entao o usuario pode refazer.
    assert_button "Pick this Epic"
  end

  test "Epic page lists who picked and links to their profiles" do
    visit epic_path(@public_epic)
    click_button "Pick this Epic"

    assert_text "1 Pick"
    # O nav tambem tem um link "@uriel", entao a busca e feita dentro da
    # lista de pickers.
    within("ul") { click_link "@#{@user.username}" }

    assert_current_path profile_path(@user)
  end

  test "Unpicking from discover keeps the user on discover" do
    visit epic_path(@public_epic)
    click_button "Pick this Epic"

    visit discover_path
    click_button "Picked ✓"

    assert_text "Pick desfeito."
  end

  test "User cannot pick private epic" do
    visit epic_path(@private_epic)

    # O Epic privado e de outro user, entao a pagina inteira e negada — mais
    # forte do que apenas esconder o botao de Pick.
    assert_text "Epic não encontrado."
    assert_no_button "Pick this Epic"
  end

  test "User cannot pick own epic" do
    own_epic = Epic.create!(
      user: @user,
      track: create_track,
      title: "My Epic",
      start_time: 200_000,
      end_time: 300_000,
      visibility: :public
    )

    visit epic_path(own_epic)

    assert_text "My Epic"
    assert_no_button "Pick this Epic"
  end
end
