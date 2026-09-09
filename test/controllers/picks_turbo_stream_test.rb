require "test_helper"

class PicksTurboStreamTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_as
    @other = User.create!(username: "other")
    track = Track.create!(spotify_id: "ts1", name: "S", artist_name: "A", duration_ms: 200_000)
    @epic = Epic.create!(user: @other, track: track, title: "E",
                         start_time: 0, end_time: 5_000, visibility: :public)
  end

  test "picking over turbo stream swaps the button without a redirect" do
    post epic_pick_path(@epic), as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match "pick_button_epic_#{@epic.id}", response.body
    # O botao volta no estado oposto: agora e o de desfazer.
    assert_match "Picked ✓", response.body
  end

  test "the stream carries the updated count and picker list" do
    post epic_pick_path(@epic), as: :turbo_stream

    assert_match "pick_count_epic_#{@epic.id}", response.body
    assert_match "1 Pick", response.body
    assert_match "pickers_epic_#{@epic.id}", response.body
    assert_match "@#{@user.username}", response.body
  end

  test "unpicking over turbo stream restores the pick button" do
    Pick.create!(user: @user, epic: @epic)

    delete epic_pick_path(@epic), as: :turbo_stream

    assert_response :success
    assert_match "0 Picks", response.body
    assert_match "Ninguém pickou este Epic ainda", response.body
  end

  test "a plain request still redirects, so no-JS keeps working" do
    post epic_pick_path(@epic)

    assert_response :redirect
  end

  test "the flash is delivered in the stream" do
    post epic_pick_path(@epic), as: :turbo_stream

    assert_match "flash", response.body
    assert_match "Epic foi pickado!", response.body
  end
end
