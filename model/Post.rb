require_relative("Db.rb")
require_relative("Model.rb")
require_relative("Rating.rb")

class CommentNode
    attr_reader :post, :children

    def initialize(post)
        @post = post
        @children = []
    end

    def addChild(commen_node)
        @children << commen_node
    end
end

class Post < Model

    attr_reader :id, :user_id, :title, :content, :image_name, :parent_post_id, :base_post_id, :depth, :user_name, :base_post_title, :date, :rating

    def initialize(id, user_id, title, content, image_name, parent_post_id, base_post_id, depth, user_name, base_post_title, date, rating)
        @id = id
        @user_id = user_id
        @title = title
        @content = content
        @image_name = image_name
        @parent_post_id = parent_post_id
        @base_post_id = base_post_id
        @depth = depth
        @user_name = user_name
        @base_post_title = base_post_title
        @date = date
        @rating = rating
    end

    def update()
        db = Db.get()
        db.execute("UPDATE posts SET rating = ? WHERE id = ?;", @rating, @id) # Currently only updates rating
    end

    def rate(rating, user_id)
        rating = rating.to_i()

        if(rating > 0)
            rating = 1
        elsif(rating < 0)
            rating = -1
        end

        ratingDelta = Rating.insert(@id, user_id, rating)

        @rating += ratingDelta
        update()
    end

    def self.getBaseQueryString(additionalSelect: "")
        if(additionalSelect != "")
            additionalSelect = ", " + additionalSelect
        end
        return "SELECT posts.*, users.name, basePost.title AS basePostTitle #{additionalSelect}
        FROM posts INNER JOIN users ON posts.user_id = users.id
        LEFT JOIN posts AS basePost ON posts.base_post_id = basePost.id"
    end

    def self.find_by(id: nil, user_id: nil, title: nil, content: nil, image_name: nil, parent_post_id: nil, base_post_id: nil, depth: nil, order: nil, follower_id: nil, rating: nil)
        queryString = getBaseQueryString()
        if(follower_id != nil)
            queryString += " INNER JOIN follows ON posts.user_id = follows.followee_id"
        end

        search_strings = getSearchStrings(id, user_id, title, content, image_name, parent_post_id, base_post_id, depth, follower_id, rating)
        
        queryString += createSearchString(search_strings)
        queryString += createOrderString(order)

        return makeObjectArray(queryString)
    end

    def self.insert(user_id, title, content, image_name, parent_post_id, base_post_id, depth)
        db = Db.get()

		db.execute("INSERT INTO posts (user_id, title, content, image_name, parent_post_id, base_post_id, depth, date, rating) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);", user_id, title, content, image_name, parent_post_id, base_post_id, depth, Time.now().to_i(), 0)
    end

    def self.initFromDBData(data)
        return Post.new(data['id'], data['user_id'], data['title'], data['content'], data['image_name'], data['parent_post_id'], data['base_post_id'], data['depth'], data['name'], data['basePostTitle'], getCreationTime(data['date']), data['rating'])
    end

    private
    def self.getSearchStrings(id, user_id, title, content, image_id, parent_post_id, base_post_id, depth, follower_id, rating)
        search_strings = []

        Post.addStringToQuery("posts.id", id, search_strings)
        Post.addStringToQuery("posts.user_id", user_id, search_strings)
        Post.addStringToQuery("posts.title", title, search_strings)
        Post.addStringToQuery("posts.content", content, search_strings)
        Post.addStringToQuery("posts.image_name", image_id, search_strings)
        Post.addStringToQuery("posts.parent_post_id", parent_post_id, search_strings)
        Post.addStringToQuery("posts.base_post_id", base_post_id, search_strings)
        Post.addStringToQuery("posts.depth", depth, search_strings)
        Post.addStringToQuery("follows.follower_id", follower_id, search_strings)
        Post.addStringToQuery("posts.rating", rating, search_strings)

        return search_strings
    end

    def self.makeObjectArray(queryString)
        db = Db.get()

        posts_db = db.execute(queryString)

        return_array = []
        
        posts_db.each do |data|
            return_array << initFromDBData(data)
        end

        return return_array
    end

end