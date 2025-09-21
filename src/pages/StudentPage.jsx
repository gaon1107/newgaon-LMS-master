import React, { useState, useEffect } from 'react'
import { useLMS } from '../contexts/LMSContext'
import {
  Box,
  Typography,
  Button,
  TextField,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Avatar,
  FormControlLabel,
  Checkbox,
  Divider,
  Alert
} from '@mui/material'
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon
} from '@mui/icons-material'

const StudentPage = () => {
  const { students, lectures, addStudent, updateStudent, deleteStudent } = useLMS()
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedClass, setSelectedClass] = useState('')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editingStudent, setEditingStudent] = useState(null)
  const [photoDialogOpen, setPhotoDialogOpen] = useState(false)
  const [cameraStream, setCameraStream] = useState(null)
  const [showCamera, setShowCamera] = useState(false)

  const [formData, setFormData] = useState({
    name: '',
    school: '',
    grade: '',
    department: '',
    phone: '',
    parentPhone: '',
    email: '',
    class: '',
    birthDate: '',
    address: '',
    notes: '',
    // 추가된 필드들
    selectedClasses: [],
    classFee: 0,
    paymentDueDate: '',
    sendPaymentNotification: true,
    profileImage: null,
    capturedImage: null,
    // 자동 메시지 설정
    autoMessages: {
      attendance: true,    // 등하원 (기본 체크)
      outing: false,       // 외출/복귀
      imagePost: false,    // 이미지포함
      studyMonitoring: false  // 학습관제
    }
  })

  const mockClasses = [
    { id: '', name: '전체' },
    ...lectures.map(lecture => ({
      id: lecture.id,
      name: lecture.name,
      fee: lecture.fee
    }))
  ]

  const mockDepartments = [
    { id: 'math', name: '수학과' },
    { id: 'english', name: '영어과' },
    { id: 'science', name: '과학과' },
    { id: 'korean', name: '국어과' },
    { id: 'social', name: '사회과' },
    { id: 'art', name: '예체과' }
  ]


  const resetForm = () => {
    setFormData({
      name: '',
      school: '',
      grade: '',
      department: '',
      phone: '',
      parentPhone: '',
      email: '',
      class: '',
      birthDate: '',
      address: '',
      notes: '',
      selectedClasses: [],
      classFee: 0,
      paymentDueDate: '',
      sendPaymentNotification: true,
      profileImage: null,
      capturedImage: null,
      autoMessages: {
        attendance: true,
        outing: false,
        imagePost: false,
        studyMonitoring: false
      }
    })
  }

  const handleOpenDialog = (student = null) => {
    if (student) {
      setEditingStudent(student)
      setFormData(student)
    } else {
      setEditingStudent(null)
      resetForm()
    }
    setDialogOpen(true)
  }

  const handleCloseDialog = () => {
    setDialogOpen(false)
    setEditingStudent(null)
    resetForm()
  }

  const handleInputChange = (field) => (event) => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value

    setFormData(prev => {
      const newData = {
        ...prev,
        [field]: value
      }

      // 강의 선택 시 비용 자동 설정 (다중 선택)
      if (field === 'selectedClasses') {
        const selectedClassesInfo = value.map(classId => mockClasses.find(c => c.id === classId)).filter(Boolean)
        const totalFee = selectedClassesInfo.reduce((sum, cls) => sum + (cls.fee || 0), 0)
        const classNames = selectedClassesInfo.map(cls => cls.name).join(', ')

        newData.classFee = totalFee
        newData.class = classNames
      }

      return newData
    })
  }

  const handleAutoMessageChange = (messageType) => (event) => {
    const checked = event.target.checked
    setFormData(prev => ({
      ...prev,
      autoMessages: {
        ...prev.autoMessages,
        [messageType]: checked
      }
    }))
  }

  const handleImageUpload = (event) => {
    const file = event.target.files[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        setFormData(prev => ({
          ...prev,
          profileImage: e.target.result
        }))
      }
      reader.readAsDataURL(file)
    }
  }

  const handlePhotoOptionClick = () => {
    setPhotoDialogOpen(true)
  }

  const handleCameraCapture = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          width: { ideal: 1280 },
          height: { ideal: 720 }
        }
      })
      setCameraStream(stream)
      setShowCamera(true)
      setPhotoDialogOpen(false)
    } catch (error) {
      console.error('카메라 접근 오류:', error)
      alert('카메라에 접근할 수 없습니다. 권한을 확인해주세요.')
    }
  }

  const handleFileSelect = () => {
    document.getElementById('photo-upload').click()
    setPhotoDialogOpen(false)
  }

  const capturePhoto = () => {
    const video = document.getElementById('camera-video')
    const canvas = document.createElement('canvas')
    const context = canvas.getContext('2d')

    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    context.drawImage(video, 0, 0)

    const capturedImageData = canvas.toDataURL('image/jpeg')
    setFormData(prev => ({
      ...prev,
      profileImage: capturedImageData
    }))

    stopCamera()
  }

  const stopCamera = () => {
    if (cameraStream) {
      cameraStream.getTracks().forEach(track => track.stop())
      setCameraStream(null)
    }
    setShowCamera(false)
  }

  const handleSubmit = async (event) => {
    event.preventDefault()

    try {
      if (editingStudent) {
        console.log('학생 수정:', formData)
        updateStudent(editingStudent.id, formData)
      } else {
        console.log('학생 추가:', formData)
        addStudent(formData)
      }

      handleCloseDialog()
    } catch (error) {
      console.error('학생 저장 실패:', error)
    }
  }

  const handleDelete = async (studentId) => {
    if (window.confirm('정말 삭제하시겠습니까?')) {
      try {
        console.log('학생 삭제:', studentId)
        deleteStudent(studentId)
      } catch (error) {
        console.error('학생 삭제 실패:', error)
      }
    }
  }

  const filteredStudents = students.filter(student =>
    student.name.toLowerCase().includes(searchTerm.toLowerCase()) &&
    (selectedClass === '' || student.class === mockClasses.find(c => c.id === selectedClass)?.name)
  )

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          학생 관리
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          학생 추가
        </Button>
      </Box>

      {/* 검색 및 필터 */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                placeholder="학생 이름 검색"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />
                }}
              />
            </Grid>
            <Grid item xs={12} sm={4}>
              <FormControl fullWidth>
                <InputLabel>반 필터</InputLabel>
                <Select
                  value={selectedClass}
                  onChange={(e) => setSelectedClass(e.target.value)}
                  label="반 필터"
                >
                  {mockClasses.map((cls) => (
                    <MenuItem key={cls.id} value={cls.id}>
                      {cls.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={2}>
              <Typography variant="body2" color="text.secondary">
                총 {filteredStudents.length}명
              </Typography>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* 학생 목록 테이블 */}
      <Card>
        <CardContent>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>프로필</TableCell>
                  <TableCell>이름</TableCell>
                  <TableCell>학교/학년</TableCell>
                  <TableCell>학과</TableCell>
                  <TableCell>반</TableCell>
                  <TableCell>수강료</TableCell>
                  <TableCell>연락처</TableCell>
                  <TableCell>학부모 연락처</TableCell>
                  <TableCell>결제일</TableCell>
                  <TableCell>관리</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredStudents.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={10} align="center">
                      학생 데이터가 없습니다.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredStudents.map((student) => (
                    <TableRow key={student.id}>
                      <TableCell>
                        {student.profileImage ? (
                          <Avatar
                            src={student.profileImage}
                            sx={{ width: 40, height: 40 }}
                          />
                        ) : (
                          <Avatar sx={{ width: 40, height: 40 }}>
                            {student.name.charAt(0)}
                          </Avatar>
                        )}
                      </TableCell>
                      <TableCell>{student.name}</TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {student.school}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {student.grade}학년
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip label={student.department} size="small" color="secondary" />
                      </TableCell>
                      <TableCell>
                        <Chip label={student.class} size="small" />
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" fontWeight="bold" color="primary">
                          {student.classFee ? `${student.classFee.toLocaleString()}원` : '-'}
                        </Typography>
                      </TableCell>
                      <TableCell>{student.phone}</TableCell>
                      <TableCell>{student.parentPhone}</TableCell>
                      <TableCell>
                        <Typography variant="body2" color="text.secondary">
                          {student.paymentDueDate ? `매월 ${student.paymentDueDate.split('-')[2]}일` : '-'}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <IconButton
                          size="small"
                          onClick={() => handleOpenDialog(student)}
                          sx={{ mr: 1 }}
                        >
                          <EditIcon />
                        </IconButton>
                        <IconButton
                          size="small"
                          color="error"
                          onClick={() => handleDelete(student.id)}
                        >
                          <DeleteIcon />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* 학생 추가/수정 다이얼로그 */}
      <Dialog
        open={dialogOpen}
        onClose={(event, reason) => {
          if (reason !== 'backdropClick' && reason !== 'escapeKeyDown') {
            handleCloseDialog()
          }
        }}
        disableEscapeKeyDown
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          {editingStudent ? '학생 정보 수정' : '새 학생 추가'}
        </DialogTitle>
        <DialogContent>
          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1 }}>
            <Grid container spacing={2}>
              {/* 좌측: 학생 정보 */}
              <Grid item xs={12} md={8}>
                <Typography variant="h6" gutterBottom color="primary">
                  학생 정보
                </Typography>
                <Grid container spacing={2}>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="이름 *"
                      value={formData.name}
                      onChange={handleInputChange('name')}
                      required
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="학교"
                      value={formData.school}
                      onChange={handleInputChange('school')}
                      placeholder="가온 중학교 3"
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="학년"
                      value={formData.grade}
                      onChange={handleInputChange('grade')}
                      placeholder="3"
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <FormControl fullWidth>
                      <InputLabel>학과</InputLabel>
                      <Select
                        value={formData.department}
                        onChange={handleInputChange('department')}
                        label="학과"
                      >
                        {mockDepartments.map((dept) => (
                          <MenuItem key={dept.id} value={dept.name}>
                            {dept.name}
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="학생 연락처"
                      value={formData.phone}
                      onChange={handleInputChange('phone')}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="학부모 연락처 *"
                      value={formData.parentPhone}
                      onChange={handleInputChange('parentPhone')}
                      required
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="이메일"
                      type="email"
                      value={formData.email}
                      onChange={handleInputChange('email')}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <FormControl fullWidth>
                      <InputLabel>강의 선택 * (다중 선택 가능)</InputLabel>
                      <Select
                        multiple
                        value={formData.selectedClasses}
                        onChange={handleInputChange('selectedClasses')}
                        label="강의 선택 * (다중 선택 가능)"
                        required
                        renderValue={(selected) => (
                          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                            {selected.map((value) => {
                              const cls = mockClasses.find(c => c.id === value)
                              return cls ? (
                                <Chip key={value} label={cls.name} size="small" />
                              ) : null
                            })}
                          </Box>
                        )}
                      >
                        {mockClasses.filter(c => c.id !== '').map((cls) => (
                          <MenuItem key={cls.id} value={cls.id}>
                            <Checkbox checked={formData.selectedClasses.indexOf(cls.id) > -1} />
                            {cls.name} - {cls.fee.toLocaleString()}원
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Grid>

                  {/* 선택된 강의 비용 표시 */}
                  {formData.selectedClasses.length > 0 && formData.classFee > 0 && (
                    <Grid item xs={12}>
                      <Alert severity="info">
                        선택된 강의: <strong>{formData.class}</strong><br/>
                        총 월 수강료: <strong>{formData.classFee.toLocaleString()}원</strong>
                        {formData.selectedClasses.length > 1 && (
                          <>
                            <br/>
                            <Typography variant="caption" color="text.secondary">
                              {formData.selectedClasses.length}개 강의 선택됨
                            </Typography>
                          </>
                        )}
                      </Alert>
                    </Grid>
                  )}

                  {/* 결제 정보 섹션 */}
                  <Grid item xs={12}>
                    <Divider sx={{ my: 2 }}>
                      <Typography variant="h6" color="primary">
                        결제 정보
                      </Typography>
                    </Divider>
                  </Grid>

                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="수강료"
                      value={formData.classFee > 0 ? `${formData.classFee.toLocaleString()}원` : ''}
                      disabled
                      helperText="선택한 강의에 따라 자동 설정됩니다"
                    />
                  </Grid>

                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="결제일 *"
                      type="date"
                      value={formData.paymentDueDate}
                      onChange={handleInputChange('paymentDueDate')}
                      InputLabelProps={{
                        shrink: true,
                      }}
                      required
                      helperText="매월 결제해야 할 날짜를 지정해주세요"
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.sendPaymentNotification}
                          onChange={handleInputChange('sendPaymentNotification')}
                          color="primary"
                        />
                      }
                      label="결제 안내 문자 발송 (결제 기한일 전에 알림 문자를 발송합니다)"
                    />
                  </Grid>

                  {/* 자동 메시지 설정 섹션 */}
                  <Grid item xs={12}>
                    <Divider sx={{ my: 2 }}>
                      <Typography variant="h6" color="primary">
                        자동 메시지 설정
                      </Typography>
                    </Divider>
                  </Grid>

                  <Grid item xs={12}>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                      자동으로 발송할 메시지 유형을 선택해주세요.
                    </Typography>

                    <Grid container spacing={2}>
                      <Grid item xs={12} sm={4}>
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={formData.autoMessages.attendance}
                              onChange={handleAutoMessageChange('attendance')}
                              color="primary"
                            />
                          }
                          label="📚 등하원"
                        />
                      </Grid>

                      <Grid item xs={12} sm={4}>
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={formData.autoMessages.outing}
                              onChange={handleAutoMessageChange('outing')}
                              color="primary"
                            />
                          }
                          label="🚶 외출/복귀"
                        />
                      </Grid>

                      <Grid item xs={12} sm={4}>
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={formData.autoMessages.imagePost}
                              onChange={handleAutoMessageChange('imagePost')}
                              color="primary"
                            />
                          }
                          label="📷 이미지포함"
                        />
                      </Grid>
                    </Grid>

                    {/* 학습관제 섹션 */}
                    <Grid container spacing={2} sx={{ mt: 1 }}>
                      <Grid item xs={12}>
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={formData.autoMessages.studyMonitoring}
                              onChange={handleAutoMessageChange('studyMonitoring')}
                              color="primary"
                            />
                          }
                          label="📊 학습관제 대상"
                        />
                      </Grid>
                    </Grid>
                  </Grid>

                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="생년월일"
                      type="date"
                      value={formData.birthDate}
                      onChange={handleInputChange('birthDate')}
                      InputLabelProps={{
                        shrink: true,
                      }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="주소"
                      value={formData.address}
                      onChange={handleInputChange('address')}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="비고"
                      multiline
                      rows={3}
                      value={formData.notes}
                      onChange={handleInputChange('notes')}
                    />
                  </Grid>
                </Grid>
              </Grid>

              {/* 우측: 학생 사진 */}
              <Grid item xs={12} md={4}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="h6" gutterBottom color="primary">
                    학생 사진
                  </Typography>
                  <Box
                    sx={{
                      width: '200px',
                      height: '250px',
                      border: '2px dashed #ccc',
                      borderRadius: '8px',
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      justifyContent: 'center',
                      mx: 'auto',
                      mb: 2,
                      cursor: 'pointer',
                      '&:hover': {
                        borderColor: '#1976d2'
                      }
                    }}
                    onClick={handlePhotoOptionClick}
                  >
                    {formData.profileImage ? (
                      <img
                        src={formData.profileImage}
                        alt="학생 사진"
                        style={{
                          width: '100%',
                          height: '100%',
                          objectFit: 'cover',
                          borderRadius: '6px'
                        }}
                      />
                    ) : (
                      <>
                        <Avatar sx={{ width: 80, height: 80, mb: 2 }}>
                          <Typography variant="h4">📷</Typography>
                        </Avatar>
                        <Typography variant="body2" color="text.secondary">
                          클릭하여 사진을 등록하세요<br/>
                          카메라 촬영 또는<br/>
                          파일에서 선택 가능
                        </Typography>
                      </>
                    )}
                  </Box>
                  <input
                    id="photo-upload"
                    type="file"
                    accept="image/*"
                    style={{ display: 'none' }}
                    onChange={handleImageUpload}
                  />
                  <Button
                    variant="outlined"
                    onClick={handlePhotoOptionClick}
                    sx={{ mb: 1 }}
                  >
                    사진 선택
                  </Button>
                  {formData.profileImage && (
                    <Button
                      variant="text"
                      color="error"
                      onClick={() => setFormData(prev => ({ ...prev, profileImage: null }))}
                      sx={{ display: 'block', mx: 'auto' }}
                    >
                      사진 삭제
                    </Button>
                  )}
                </Box>
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>
            취소
          </Button>
          <Button
            onClick={handleSubmit}
            variant="contained"
            disabled={!formData.name || !formData.parentPhone || formData.selectedClasses.length === 0 || !formData.paymentDueDate}
          >
            {editingStudent ? '수정' : '추가'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* 사진 선택 옵션 다이얼로그 */}
      <Dialog
        open={photoDialogOpen}
        onClose={(event, reason) => {
          if (reason !== 'backdropClick' && reason !== 'escapeKeyDown') {
            setPhotoDialogOpen(false)
          }
        }}
        disableEscapeKeyDown
      >
        <DialogTitle>사진 선택 방법</DialogTitle>
        <DialogContent>
          <Typography variant="body1" sx={{ mb: 2 }}>
            학생 사진을 등록할 방법을 선택해주세요.
          </Typography>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <Button
              variant="outlined"
              startIcon={<Typography>📷</Typography>}
              onClick={handleCameraCapture}
              sx={{ p: 2, justifyContent: 'flex-start' }}
            >
              카메라로 촬영하기
            </Button>
            <Button
              variant="outlined"
              startIcon={<Typography>📁</Typography>}
              onClick={handleFileSelect}
              sx={{ p: 2, justifyContent: 'flex-start' }}
            >
              파일에서 선택하기
            </Button>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPhotoDialogOpen(false)}>취소</Button>
        </DialogActions>
      </Dialog>

      {/* 카메라 촬영 다이얼로그 */}
      <Dialog
        open={showCamera}
        onClose={(event, reason) => {
          if (reason !== 'backdropClick' && reason !== 'escapeKeyDown') {
            stopCamera()
          }
        }}
        disableEscapeKeyDown
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>카메라로 사진 촬영</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
            <video
              id="camera-video"
              autoPlay
              playsInline
              muted
              ref={(video) => {
                if (video && cameraStream) {
                  video.srcObject = cameraStream
                }
              }}
              style={{
                width: '100%',
                maxWidth: '500px',
                height: 'auto',
                borderRadius: '8px',
                border: '2px solid #ccc'
              }}
            />
            <Box sx={{ display: 'flex', gap: 2 }}>
              <Button
                variant="contained"
                color="primary"
                onClick={capturePhoto}
                startIcon={<Typography>📸</Typography>}
              >
                사진 촬영
              </Button>
              <Button
                variant="outlined"
                onClick={stopCamera}
              >
                취소
              </Button>
            </Box>
          </Box>
        </DialogContent>
      </Dialog>
    </Box>
  )
}

export default StudentPage
