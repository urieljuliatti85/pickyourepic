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
      # O form fala em MM:SS; o Epic converte para os ms das colunas.
      assert_select "input[name='epic[start_time_mmss]']"
      assert_select "input[name='epic[end_time_mmss]']"
    end
  end

  test "GET /epics/new displays track info" do
    get new_epic_path(track_id: @track.spotify_id)

    assert_response :success
    assert_select "h1", "Create Epic"
    assert_select "strong", @track.name
    assert_select "p", /Test Artist/
  end

  test "POST /epics creates epic" do
    assert_difference "Epic.count", 1 do
      post epics_path, params: {
        epic: {
          title: "My Epic",
          description: "Great moment",
          start_time_mmss: "1:00",
          end_time_mmss: "2:00",
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
        start_time_mmss: "1:00",
        end_time_mmss: "2:00",
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
          start_time_mmss: "1:40",
          end_time_mmss: "0:50",  # Invalid: end < start
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
          start_time_mmss: "1:00",
          end_time_mmss: "2:00",
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
    assert_equal "Epic not found.", flash[:alert]
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
    # O trecho e um bloco so: "1:00 – 3:00" (en-dash) e, abaixo, a duracao.
    assert_select "p", /1:00.*3:00/m
    assert_select "p", /2:00/  # duration: 3:00 - 1:00 = 2:00
  end

  # show_exceptions = :rescuable no ambiente de teste converte o
  # RecordNotFound em resposta 404 em vez de propagar a excecao.
  test "POST /epics with invalid track_id returns not found" do
    post epics_path, params: {
      epic: {
        title: "My Epic",
        start_time_mmss: "1:00",
        end_time_mmss: "2:00",
        visibility: "public"
      },
      track_id: "nonexistent"
    }

    assert_response :not_found
  end

  # DESTROY

  def own_epic(visibility: :public)
    Epic.create!(user: @user, track: @track, title: "Meu Epic",
                 start_time: 0, end_time: 30_000, visibility: visibility)
  end

  test "DELETE /epics/:id destroys the owner's epic" do
    epic = own_epic

    assert_difference "Epic.count", -1 do
      delete epic_path(epic)
    end

    assert_redirected_to profile_path(@user)
    assert_equal "Epic deleted.", flash[:notice]
  end

  test "DELETE /epics/:id destroys a private epic too" do
    epic = own_epic(visibility: :private)

    assert_difference "Epic.count", -1 do
      delete epic_path(epic)
    end

    assert_redirected_to profile_path(@user)
  end

  test "DELETE /epics/:id rejects a non-owner" do
    other = User.create!(username: "alice")
    epic = Epic.create!(user: other, track: @track, title: "Da Alice",
                        start_time: 0, end_time: 30_000, visibility: :public)

    assert_no_difference "Epic.count" do
      delete epic_path(epic)
    end

    assert_redirected_to epic_path(epic)
    assert_equal "Not authorized.", flash[:alert]
  end

  test "DELETE /epics/:id requires authentication" do
    epic = own_epic
    delete sign_out_path

    assert_no_difference "Epic.count" do
      delete epic_path(epic)
    end

    assert_redirected_to root_path
  end

  # What the Epic received goes with it (dependent: :destroy), or Picks and
  # Collection rows would be left pointing at an Epic that no longer exists.
  test "DELETE /epics/:id takes its picks, favorites and collection rows with it" do
    epic = own_epic
    picker = User.create!(username: "picker")
    Pick.create!(user: picker, epic: epic)
    Favorite.create!(user: @user, epic: epic)
    collection = Collection.create!(user: picker, title: "Col", visibility: :public)
    CollectionEpic.create!(collection: collection, epic: epic)

    delete epic_path(epic)

    assert_equal 0, Pick.where(epic_id: epic.id).count
    assert_equal 0, Favorite.where(epic_id: epic.id).count
    assert_equal 0, CollectionEpic.where(epic_id: epic.id).count
    assert Collection.exists?(collection.id), "a Collection em si nao deve sumir"
  end

  # With no button, the page says why — an empty slot reads as a bug.
  test "GET /epics/:id explains why your own Epic has no Pick button" do
    epic = own_epic

    get epic_path(epic)

    assert_select "button[type=submit]", { text: "Pick", count: 0 }
    assert_match "This Epic is yours", response.body
  end

  test "GET /epics/:id invites a signed out visitor to sign in" do
    epic = own_epic
    delete sign_out_path

    get epic_path(epic)

    assert_select "button[type=submit]", { text: "Pick", count: 0 }
    assert_match "Sign in to pick", response.body
  end

  test "GET /epics/:id shows no note when the Pick button is there" do
    other = User.create!(username: "carol")
    epic = Epic.create!(user: other, track: @track, title: "Da Carol",
                        start_time: 0, end_time: 30_000, visibility: :public)

    get epic_path(epic)

    assert_select "button[type=submit]", text: "Pick"
    assert_no_match "This Epic is yours", response.body
  end

  # The button only shows to the owner: a visitor should not even see the option.
  test "GET /epics/:id shows the delete button only to the owner" do
    epic = own_epic

    get epic_path(epic)
    assert_select "button[type=submit]", text: "Delete"

    sign_in_as(create_signed_in_user(username: "bob"))
    get epic_path(epic)
    assert_select "button[type=submit]", { text: "Delete", count: 0 }
  end
end
