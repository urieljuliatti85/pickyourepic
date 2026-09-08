require "test_helper"

class EpicsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = sign_in_as(create_signed_in_user)
    @track = Track.create!(
      spotify_id: "track_123",
      name: "Test Song",
      artist_name: "Test Artist",
      duration_ms: 300_000
    )
  end

  test "GET /epics/new requires authentication" do
    # Simular logout
    delete sign_out_path
    get new_epic_path(track_id: @track.spotify_id)

    assert_redirected_to root_path
    assert_equal "Sign in with Spotify to continue.", flash[:alert]
  end

  test "GET /epics/new displays form" do
    get new_epic_path(track_id: @track.spotify_id)

    assert_response :success
    assert_select "form" do
      assert_select "input[name='epic[title]']"
      assert_select "textarea[name='epic[description]']"
      assert_select "input[name='epic[start_time]']"
      assert_select "input[name='epic[end_time]']"
    end
  end

  test "GET /epics/new displays track info" do
    get new_epic_path(track_id: @track.spotify_id)

    assert_response :success
    assert_select "strong", @track.name
    assert_select "p", /Test Artist/
  end

  test "POST /epics creates epic" do
    assert_difference "Epic.count", 1 do
      post epics_path, params: {
        epic: {
          title: "My Epic",
          description: "Great moment",
          start_time: 60_000,
          end_time: 120_000,
          visibility: "public"
        },
        track_id: @track.spotify_id
      }
    end

    assert_redirected_to epic_path(Epic.last)
  end

  test "POST /epics sets current_user as owner" do
    post epics_path, params: {
      epic: {
        title: "My Epic",
        start_time: 60_000,
        end_time: 120_000,
        visibility: "public"
      },
      track_id: @track.spotify_id
    }

    epic = Epic.last
    assert_equal @user.id, epic.user_id
  end

  test "POST /epics rejects invalid timestamps" do
    assert_no_difference "Epic.count" do
      post epics_path, params: {
        epic: {
          title: "My Epic",
          start_time: 100_000,
          end_time: 50_000,  # Invalid: end < start
          visibility: "public"
        },
        track_id: @track.spotify_id
      }
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation"
  end

  test "POST /epics rejects missing title" do
    assert_no_difference "Epic.count" do
      post epics_path, params: {
        epic: {
          title: "",
          start_time: 60_000,
          end_time: 120_000,
          visibility: "public"
        },
        track_id: @track.spotify_id
      }
    end

    assert_response :unprocessable_entity
  end

  test "GET /epics/:id displays epic" do
    epic = Epic.create!(
      user: @user,
      track: @track,
      title: "My Epic",
      description: "A great moment",
      start_time: 60_000,
      end_time: 120_000
    )

    get epic_path(epic)

    assert_response :success
    assert_select "h1", "My Epic"
    assert_select "strong", @track.name
    assert_select "p", /A great moment/
  end

  test "GET /epics/:id shows public epic to any user" do
    other_user = User.create!(username: "other")
    epic = Epic.create!(
      user: other_user,
      track: @track,
      title: "Other's Public Epic",
      start_time: 60_000,
      end_time: 120_000,
      visibility: :public
    )

    get epic_path(epic)

    assert_response :success
    assert_match CGI.escapeHTML("Other's Public Epic"), response.body
  end

  test "GET /epics/:id redirects for private epic of other user" do
    other_user = User.create!(username: "other")
    epic = Epic.create!(
      user: other_user,
      track: @track,
      title: "Private Epic",
      start_time: 60_000,
      end_time: 120_000,
      visibility: :private
    )

    get epic_path(epic)

    assert_redirected_to root_path
    assert_equal "Epic não encontrado.", flash[:alert]
  end

  test "GET /epics/:id works without authentication for public epic" do
    delete sign_out_path
    other_user = User.create!(username: "other")
    epic = Epic.create!(user: other_user, track: @track, title: "Public", start_time: 0, end_time: 100_000, visibility: :public)

    get epic_path(epic)

    assert_response :success
    assert_match "Public", response.body
  end

  test "GET /epics/:id shows visibility badge" do
    public_epic = Epic.create!(
      user: @user,
      track: @track,
      title: "Public Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )

    get epic_path(public_epic)

    assert_response :success
    assert_select "span", /Public/
  end

  test "GET /epics/:id shows private badge" do
    private_epic = Epic.create!(
      user: @user,
      track: @track,
      title: "Private Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :private
    )

    get epic_path(private_epic)

    assert_response :success
    assert_select "span", /Private/
  end

  test "GET /epics/:id shows correct durations" do
    epic = Epic.create!(
      user: @user,
      track: @track,
      title: "My Epic",
      start_time: 60_000,  # 1:00
      end_time: 180_000    # 3:00
    )

    get epic_path(epic)

    assert_response :success
    assert_select "p", /1:00 - 3:00/
    assert_select "p", /2:00/  # duration: 3:00 - 1:00 = 2:00
  end

  # show_exceptions = :rescuable no ambiente de teste converte o
  # RecordNotFound em resposta 404 em vez de propagar a excecao.
  test "POST /epics with invalid track_id returns not found" do
    post epics_path, params: {
      epic: {
        title: "My Epic",
        start_time: 60_000,
        end_time: 120_000,
        visibility: "public"
      },
      track_id: "nonexistent"
    }

    assert_response :not_found
  end
end
